defmodule NervesInitEc2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: NervesInitEc2.Worker.start_link(arg)
      # {NervesInitEc2.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesInitEc2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
