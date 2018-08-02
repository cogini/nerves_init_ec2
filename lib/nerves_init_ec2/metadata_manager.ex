defmodule NervesInitEc2.MetadataManager do
  @moduledoc "Configure SystemRegistry from EC2 metadata"

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([opts]) do
    Logger.debug("#{__MODULE__}: opts: #{inspect opts}")
    SystemRegistry.register()

    set_defaults(opts)

    {:ok, %{ip: nil, ifname: "eth0"}}
  end

  def set_defaults(opts) do
    SystemRegistry.transaction(priority: :default)
    |> SystemRegistry.update([:config, :ssh, :authorized_keys], opts.ssh_authorized_keys)
    |> SystemRegistry.update([:config, :ssh, :console_port], opts.ssh_console_port)
    |> SystemRegistry.commit
  end

  def handle_info({:system_registry, :global, registry}, state) do
    new_ip = get_in(registry, [:state, :network_interface, state.ifname, :ipv4_address])
    if new_ip == state.ip do
      {:noreply, state}
    else
      Logger.debug("IP address for #{state.ifname} changed to #{new_ip}")
      update_ssh_authorized_keys(registry)

      {:noreply, %{state | ip: new_ip}}
    end
  end

  def update_ssh_authorized_keys(registry) do
    Logger.info("Configuring from instance metadata")

    authorized_keys = get_in(registry, [:config, :ssh, :authorized_keys])

    instance_keys = case :httpc.request('http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key') do
      {:ok, {_, _, ""}} ->
        []
      {:ok, {_, _, key}} ->
        [key]
      result ->
        Logger.error("Error reading instance metadata: #{inspect result}")
        []
    end

    all_keys = authorized_keys ++ instance_keys
    Logger.debug("All ssh keys: #{inspect all_keys}")
    if length(all_keys) > 0 do
      SystemRegistry.update([:config, :ssh, :authorized_keys], all_keys)
      Application.put_env(:nerves_firmware_ssh, :authorized_keys, all_keys, persistent: true)
    end

  end

end
