#!/bin/bash
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

set -x
set -e
set -u
set -o pipefail

# Environment variables default values setup
NEUTRON_IDENTITY_URI="${NEUTRON_IDENTITY_URI:-http://127.0.0.1:35357}"
NEUTRON_SERVICE_TENANT_NAME="${NEUTRON_SERVICE_TENANT_NAME:-service}"
NEUTRON_SERVICE_USER="${NEUTRON_SERVICE_USER:-neutron}"
#NEUTRON_SERVICE_PASS
NEUTRON_RABBITMQ_HOST="${NEUTRON_RABBITMQ_HOST:-localhost}"
NEUTRON_RABBITMQ_USER="${NEUTRON_RABBITMQ_USER:-guest}"
NEUTRON_RABBITMQ_PASS="${NEUTRON_RABBITMQ_PASS:-guest}"
NEUTRON_EXTERNAL_NETWORKS="${NEUTRON_EXTERNAL_NETWORKS:-external}"
NEUTRON_BRIDGE_MAPPINGS="${NEUTRON_BRIDGE_MAPPINGS:-external:br-ex}"

MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
MY_SUBNET="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $4}')"
MY_GW=$(ip route show | awk '/default/ {print $3}')
TUNNEL_LOCAL_IP="$MY_IP"
NEUTRON_CONFIG_FILE="/etc/neutron/neutron.conf"
#DHCP_AGENT_CONFIG_FILE="/etc/neutron/dhcp_agent.ini"
PLUGIN_ML2_CONFIG_FILE="/etc/neutron/plugins/ml2/ml2_conf.ini"

# Configure the service with environment variables defined
sed -i "s#%NEUTRON_IDENTITY_URI%#${NEUTRON_IDENTITY_URI}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_TENANT_NAME%#${NEUTRON_SERVICE_TENANT_NAME}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_USER%#${NEUTRON_SERVICE_USER}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_PASS%#${NEUTRON_SERVICE_PASS}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_HOST%#${NEUTRON_RABBITMQ_HOST}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_USER%#${NEUTRON_RABBITMQ_USER}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_PASS%#${NEUTRON_RABBITMQ_PASS}#" \
    "$NEUTRON_CONFIG_FILE"

sed -i "s#%NEUTRON_EXTERNAL_NETWORKS%#${NEUTRON_EXTERNAL_NETWORKS}#" \
    "$PLUGIN_ML2_CONFIG_FILE"
sed -i "s#%TUNNEL_LOCAL_IP%#${TUNNEL_LOCAL_IP}#" "$PLUGIN_ML2_CONFIG_FILE"
sed -i "s#%NEUTRON_BRIDGE_MAPPINGS%#${NEUTRON_BRIDGE_MAPPINGS}#" \
    "$PLUGIN_ML2_CONFIG_FILE"

# Start OVS switch
/etc/init.d/openvswitch-switch start

# Create external bridge and attach eth0 to it
ovs-vsctl add-br br-ex
ip addr del "$MY_IP" dev eth0
ip addr add "$MY_IP/$MY_SUBNET" dev br-ex
ip link set dev br-ex up
ip route add default via "$MY_GW"
ovs-vsctl add-port br-ex eth0

# Start OVS agent
/usr/bin/python /usr/bin/neutron-openvswitch-agent \
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini \
    --config-file=/etc/neutron/neutron.conf &

# Start the service
neutron-dhcp-agent
