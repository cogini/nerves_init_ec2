defmodule NervesInitEc2.Options do
  @moduledoc false

  defstruct ifname: "eth0",
    address_method: :dhcp,
    net_kernel: false,
    node_name: "nerves",
    node_name_public: false,
    ssh_console_port: 22,
    ssh_authorized_keys: []
end
