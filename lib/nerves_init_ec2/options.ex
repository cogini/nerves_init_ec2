defmodule NervesInitEc2.Options do
  @moduledoc false

  defstruct ifname: "eth0",
            address_method: :dhcp,
            node_name: nil,
            node_host: :dhcp,
            ssh_console_port: nil,
            ssh_authorized_keys: nil
end
