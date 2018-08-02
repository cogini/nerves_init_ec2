defmodule NervesInitEc2.SSHConsole do
  @moduledoc """
  SSH IEx console.
  """
  use GenServer

  require Logger

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init([opts]) do
    Logger.debug("#{__MODULE__}: opts: #{inspect opts}")
    SystemRegistry.register()

    init_daemon(opts.ssh_console_port, opts.ssh_authorized_keys)
  end

  def terminate(_reason, %{daemon_ref: ref}) do
    :ssh.stop_daemon(ref)
  end

  @spec init_daemon(non_neg_integer, list(binary)) :: {:ok, Map.t}
  defp init_daemon(port, []) do
    Logger.debug("authorized_keys not defined, waiting")
    {:ok, %{keys: [], port: port}}
  end
  defp init_daemon(port, keys) do
    Logger.debug("init_daemon: Starting SSH console on port #{port}, keys #{inspect keys}")
    case start_daemon(port, keys) do
      {:ok, ref} ->
        {:ok, %{daemon_ref: ref, keys: keys, port: port}}
      {:error, reason} ->
        Logger.warn("Could not start SSH console: #{reason}")
        {:ok, %{keys: keys, port: port}}
    end
  end

  @spec start_daemon(non_neg_integer, list(binary)) :: {:ok, Map.t} | {:error, atom}
  defp start_daemon(port, config_keys) do
    string_keys = Enum.join(config_keys, "\n")
    auth_keys = :public_key.ssh_decode(string_keys, :auth_keys)
    cb_opts = [authorized_keys: auth_keys]

    :ssh.daemon(port, [
      {:id_string, :random},
      {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
      {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
      {:shell, {Elixir.IEx, :start, []}}
    ])
  end

  def handle_info({:system_registry, :global, registry}, state) do
    keys = get_in(registry, [:config, :ssh, :authorized_keys])
    restart_daemon(state, keys)
  end

  def restart_daemon(state, nil), do: {:noreply, state}
  def restart_daemon(%{keys: keys} = state, new_keys) when keys == new_keys do
    {:noreply, state}
  end
  def restart_daemon(%{daemon_ref: ref, port: port} = state, new_keys) do
    Logger.debug("restart_daemon: Stopping SSH console #{inspect ref}")
    :ssh.stop_daemon(ref)

    Logger.debug("restart_daemon: Starting SSH console on port #{port}, keys #{inspect new_keys}")
    {:ok, ref} = start_daemon(port, new_keys)
    {:noreply, %{state | daemon_ref: ref, keys: new_keys}}
  end

end
