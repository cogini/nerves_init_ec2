# nerves_init_ec2

This module initializes a Nerves system using Amazon EC2 metadata. It is similar
to [nerves_init_gadget](https://github.com/nerves-project/nerves_init_gadget), but
specialized for Amazon EC2. 

An example app that uses it is [hello_nerves_ec2](https://github.com/cogini/hello_nerves_ec2).

It does the following:

* Brings up networking
* Starts an IEx console acccessible via `ssh` using the
  [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
  specified for the instance
* Configures the node name and starts distributed Erlang [net_kernel](http://erlang.org/doc/man/net_kernel.html)

* Logging via [ring_logger](https://github.com/nerves-project/ring_logger)

## Installation

Add `nerves_init_ec2` to the deps in your project's `mix.exs`:

```elixir
  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.4"},
      {:nerves_init_ec2, "~> 0.3"}
    ] ++ system(target)
  end
```

Add `nerves_init_ec2` to the list of applications to always start in `config/config.exs`:

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_ec2],
  app: Mix.Project.config()[:app]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nerves_init_ec2](https://hexdocs.pm/nerves_init_ec2).

## Build deps

Ubuntu

```shell
sudo apt install libmnl-dev
```
