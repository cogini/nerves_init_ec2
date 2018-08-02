defmodule NervesInitEc2.NetworkManager do
  @moduledoc false

  use GenServer

  require Logger

  defmodule State do
    @moduledoc false
    defstruct ifname: "eth0", ip: nil, opts: nil
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([opts]) do
    Logger.debug("#{__MODULE__}: opts: #{inspect opts}")
    # Register for updates from system registry
    SystemRegistry.register()

    # Initialize networking
    Nerves.Network.setup(opts.ifname, ipv4_address_method: opts.address_method)
    init_net_kernel(opts)

    {:ok, %State{opts: opts}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    new_ip = get_in(registry, [:state, :network_interface, state.ifname, :ipv4_address])
    handle_ip_update(state, new_ip)
  end

  defp handle_ip_update(%{ip: old_ip} = state, new_ip) when old_ip == new_ip do
    # No change
    {:noreply, state}
  end

  defp handle_ip_update(state, new_ip) do
    Logger.debug("IP address for #{state.ifname} changed to #{new_ip}")
    update_net_kernel(new_ip, state.opts)
    {:noreply, %{state | ip: new_ip}}
  end

  defp init_net_kernel(opts) do
    if erlang_distribution_enabled?(opts) do
      :os.cmd('epmd -daemon')
    end
  end

  defp update_net_kernel(ip, opts) do
    new_name = make_node_name(opts, ip)

    if new_name do
      :net_kernel.stop()

      case :net_kernel.start([new_name]) do
        {:ok, _} ->
          Logger.debug("Restarted Erlang distribution as node #{inspect(new_name)}")
        {:error, reason} ->
          Logger.error("Erlang distribution failed to start: #{inspect(reason)}")
      end
    end
  end

  defp erlang_distribution_enabled?(opts) do
    make_node_name(opts, "fake.ip") != nil
  end

  defp resolve_dhcp_name(fallback) do
    with {:ok, hostname} <- :inet.gethostname(),
         {:ok, {:hostent, dhcp_name, _, _, _, _}} <- :inet.gethostbyname(hostname) do
      dhcp_name
    else
      _ -> fallback
    end
  end

  defp make_node_name(%{node_name: name, node_host: :ip}, ip) do
    to_node_name(name, ip)
  end

  defp make_node_name(%{node_name: name, node_host: :dhcp}, ip) do
    to_node_name(name, resolve_dhcp_name(ip))
  end

  defp make_node_name(%{node_name: name, node_host: host}, _ip) do
    to_node_name(name, host)
  end

  defp to_node_name(nil, _host), do: nil
  defp to_node_name(_name, nil), do: nil
  defp to_node_name(name, host), do: :"#{name}@#{host}"
end
