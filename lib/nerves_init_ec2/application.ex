defmodule NervesInitEc2.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    config_opts = Map.new(Application.get_all_env(:nerves_init_ec2))
    merged_opts = Map.merge(%NervesInitEc2.Options{}, config_opts)

    Logger.info("#{__MODULE__}: opts: #{inspect merged_opts}")

    children = [
      {NervesInitEc2.NetworkManager, [merged_opts]},
      {NervesInitEc2.MetadataManager, [merged_opts]},
      {NervesInitEc2.SSHConsole, [merged_opts]}
    ]

    opts = [strategy: :one_for_one, name: NervesInitEc2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
