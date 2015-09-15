#! /usr/bin/env bash
#
# Copyright (c) 2015 Davide Guerri <davide.guerri@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -uexo pipefail

IP="10.29.29.1/24"
HOST_EXTERNAL_INTERFACE="eth1"


# Container names (non-existing containers are skipped)
container_names=(
    "neutron-dhcp-agent.os-in-a-box"
    "neutron-l3-agent.os-in-a-box"
    "nova-compute.os-in-a-box"
)

# Add provisioning bridge
ovs-vsctl br-exists provisioning && ovs-vsctl del-br provisioning
ovs-vsctl add-br provisioning
ovs-vsctl add-port provisioning "$HOST_EXTERNAL_INTERFACE"
ip link set dev provisioning up
ip link set dev "$HOST_EXTERNAL_INTERFACE" up

for container_name in "${container_names[@]}"; do
    # Get docker container PID
    docker_pid=$(docker inspect --format "{{ .State.Pid }}" \
        "$container_name" || echo "not available")

    if [ "$docker_pid" == "not available" ]; then
        continue
    fi

    if_id=$(echo "$container_name"|md5sum|dd bs=1 count=5 2>/dev/null)

    # Create a veth pair
    if [ -d "/sys/class/net/if_${if_id}_0" ]; then
      ip link del dev "if_${if_id}_0"
    fi

    ip link add name "if_${if_id}_0" type veth \
        peer name "if_${if_id}_1"
    ip link set dev "if_${if_id}_0" up

    # Attach ext0 to the provisioning bridge
    ovs-vsctl add-port provisioning "if_${if_id}_0"

    # Move "if_${if_id}_1" into the neutron container
    ip link set dev "if_${if_id}_1" netns "$docker_pid"

    # Attach "if_${if_id}_1" to br-ex
    docker exec "$container_name" \
        ovs-vsctl port-to-br "if_${if_id}_1" && \
            docker exec "$container_name" \
                ovs-vsctl del-port br-ex "if_${if_id}_1"
    docker exec "$container_name" ip link set dev "if_${if_id}_1" up
    docker exec "$container_name" \
        ovs-vsctl add-port br-ex "if_${if_id}_1"
done

# Assign the IP
ip addr add "$IP" dev provisioning
