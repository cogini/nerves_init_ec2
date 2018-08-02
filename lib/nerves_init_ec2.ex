defmodule NervesInitEc2 do
  @moduledoc """
  `nerves_init_ec2` configures the instance using AWS EC2 metadata.

  Here are some features:

  * Sets up networking
  * Configures ssh keys from the keypair used to start the instance
  * Pulls in the `nerves_runtime` initialization for things like mounting and
    fixing the application filesystem
  * Starts `nerves_firmware_ssh` so that firmware push updates work
  * If used with [shoehorn](https://github.com/nerves-project/shoehorn),
    crashes in your application's initialization won't break firmware updates

  While you'll probably want to create your own device initialization project at
  some point, this project serves as a great starting point, especially if you're
  new to Nerves.

  All configuration is handled at compile-time, so there's not an API. See the
  `README.md` for installation and use instructions.
  """
end
