defmodule NervesInitEc2.MixProject do
  use Mix.Project

  @version "0.1.0"

  @description """
  Initialize Nerves system from EC2 metadata
  """

  def project do
    [
      app: :nerves_init_ec2,
      version: @version,
      description: @description,
      package: package(),
      elixir: "~> 1.6",
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {NervesInitEc2.Application, []}]
  end

  defp package() do
    %{
      maintainers: ["Jake Morrison"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/cogini/nerves_init_ec2"}
    }
  end

  defp docs() do
    [main: "readme", extras: ["README.md"]]
  end

  defp deps do
    [
      {:nerves_runtime, "~> 0.3"},
      {:nerves_network, "~> 0.3"},
      {:nerves_firmware_ssh, "~> 0.2"},
      {:ring_logger, "~> 0.4"},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
