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
      {:nerves_init_ec2, github: "cogini/nerves_init_ec2"}
    ] ++ system(target)
  end
```

Add `nerves_init_ec2` to the list of applications to always start in `config/config.exs`:

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_ec2],
  app: Mix.Project.config()[:app]
```

Configure `nerves_init_ec2`. The defaults will bring up a system with an IEx
console accessible via ssh on port 22.

```elixir
config :nerves_init_ec2,
  net_kernel: false,
  node_name: "nerves",
  node_name_public: false,
  ssh_console_port: 22,
  ssh_authorized_keys: [
  # File.read!(Path.join(System.user_home!, ".ssh/authorized_keys"))
  ]
```

`ssh_authorized_keys` defines static keys. `nerves_init_ec2` adds the instance
[key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
to this list.

If you set `net_kernel: true`, then `nerves_init_ec2` will start up
distributed Erlang. The Node name will be `node_name@ip`.
`node_name_public: false` uses the private IP of the instance,
`node_name_public: true` uses the public IP.
