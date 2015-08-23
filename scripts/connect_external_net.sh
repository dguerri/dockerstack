#!/bin/bash

set -uexo pipefail

container_name="neutron-dhcp-agent.os-in-a-box"
host_external_interface="eth1"

docker_pid="$(docker inspect --format '{{ .State.Pid }}' $container_name)"

# Add provisioning bridge
ovs-vsctl br-exists provisioning && ovs-vsctl del-br provisioning
ovs-vsctl add-br provisioning
ovs-vsctl add-port provisioning "$host_external_interface"
ip link set dev provisioning up
ip link set dev "$host_external_interface" up

# Create a veth pair
if [ -d "/sys/class/net/ext0" ]; then
  ip link del dev ext0
fi

ip link add name ext0 type veth peer name ext1
ip link set dev ext0 up

# Attack ext0 to the provisioning bridge
ovs-vsctl add-port provisioning ext0

# Move ext1 into the neutron container
ip link set dev ext1 netns "$docker_pid"

# Attach ext1 to br-ex
docker exec "$container_name" ip link set dev ext1 up
