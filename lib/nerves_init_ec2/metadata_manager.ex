defmodule NervesInitEc2.MetadataManager do
  @moduledoc "Configure SystemRegistry from EC2 instance metadata"
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html

  # @ifname "eth0"
  @metadata_sleep 200

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([opts]) do
    # Logger.debug("#{__MODULE__} opts: #{inspect opts}")
    # SystemRegistry.register()

    set_defaults(opts)
    {:ok, count} = wait_for_metadata(0)
    Logger.debug("Waited #{count * @metadata_sleep / 1_000} sec for metatdata")

    registry = SystemRegistry.match(:global, :_)
    update_ssh_authorized_keys(registry)
    start_net_kernel(opts)

    {:ok, %{ip: nil}}
  end

  # def handle_info({:system_registry, :global, registry}, state) do
  #   new_ip = get_in(registry, [:state, :network_interface, @ifname, :ipv4_address])
  #   if new_ip == state.ip do
  #     {:noreply, state}
  #   else
  #     Logger.debug("IP address for #{@ifname} changed to #{new_ip}")
  #     update_ssh_authorized_keys(registry)
  #
  #     {:noreply, %{state | ip: new_ip}}
  #   end
  # end

  def set_defaults(opts) do
    SystemRegistry.transaction(priority: :default)
    |> SystemRegistry.update([:config, :ssh, :authorized_keys], opts.ssh_authorized_keys)
    |> SystemRegistry.update([:config, :ssh, :console_port], opts.ssh_console_port)
    |> SystemRegistry.commit
  end

  # @doc "Block waiting for metadata to be available"
  defp wait_for_metadata(count) do
    case :httpc.request('http://169.254.169.254/') do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, ""}} ->
        :timer.sleep(@metadata_sleep)
        wait_for_metadata(count + 1)
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, _data}} ->
        {:ok, count}
      _ ->
        :timer.sleep(@metadata_sleep)
        wait_for_metadata(count + 1)
    end
  end

  @spec get_metadata(String.t) :: {:ok, binary} | {:error, term}
  def get_metadata(url) do
    case :httpc.request(to_charlist(url)) do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, data}} ->
        {:ok, to_string(data)}
      result ->
        Logger.debug("Could not read instance metadata: #{inspect result}")
        {:error, result}
    end
  end

  def update_ssh_authorized_keys(registry) do
    authorized_keys = get_in(registry, [:config, :ssh, :authorized_keys]) || []
    {:ok, instance_key} = get_metadata('http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key')
    update_ssh_authorized_keys(instance_key, authorized_keys)
  end

  defp update_ssh_authorized_keys(nil, _authorized_keys), do: :ok
  defp update_ssh_authorized_keys(key, authorized_keys) do
    if key not in authorized_keys do
      Logger.info("Adding SSH key from instance metadata")
      all_keys = authorized_keys ++ [key]
      SystemRegistry.update([:config, :ssh, :authorized_keys], all_keys)
      Application.put_env(:nerves_firmware_ssh, :authorized_keys, all_keys, persistent: true)
    end
  end

  defp start_net_kernel(%{net_kernel: true} = opts) do
    node_name = node_name(opts.node_name, opts.node_name_public)
    Logger.debug("Starting net_kernel with node name #{node_name}")

    :os.cmd('epmd -daemon')
    case :net_kernel.start([node_name]) do
      {:ok, _} ->
        Logger.debug("Started net_kernel as node #{node_name}")
        :ok
      {:error, reason} ->
        Logger.error("Error starting net_kernel: #{reason}")
        :error
    end
  end
  defp start_net_kernel(_opts), do: :ok

  defp node_name(node_name, true) do
    {:ok, ip} = get_metadata("http://169.254.169.254/latest/meta-data/public-ipv4")
    :"#{node_name}@#{ip}"
  end
  defp node_name(node_name, _) do
    {:ok, ip} = get_metadata("http://169.254.169.254/latest/meta-data/local-ipv4")
    :"#{node_name}@#{ip}"
  end

end
