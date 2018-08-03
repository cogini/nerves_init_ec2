defmodule NervesInitEc2.NetworkManager do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([opts]) do
    # Register for updates from system registry
    # SystemRegistry.register()

    Logger.debug("#{__MODULE__}: Intializing #{opts.ifname} with #{opts.address_method}")
    Nerves.Network.setup(opts.ifname, ipv4_address_method: opts.address_method)

    {:ok, %{ifname: opts.ifname, ip: nil}}
  end

  # def handle_info({:system_registry, :global, registry}, state) do
  #   new_ip = get_in(registry, [:state, :network_interface, state.ifname, :ipv4_address])
  #   handle_ip_update(state, new_ip)
  # end

  # defp handle_ip_update(%{ip: old_ip} = state, new_ip) when old_ip == new_ip do
  #   {:noreply, state}
  # end
  # defp handle_ip_update(state, new_ip) do
  #   Logger.debug("IP address for #{state.ifname} changed to #{new_ip}")
  #   update_net_kernel(new_ip, state.opts)
  #   {:noreply, %{state | ip: new_ip}}
  # end

end
