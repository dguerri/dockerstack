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

set -xeuo pipefail


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
NEUTRON_ENABLE_IPXE="${NEUTRON_ENABLE_IPXE:-false}"

MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
#MY_SUBNET="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $4}')"
#MY_GW=$(ip route show | awk '/default/ {print $3}')
TUNNEL_LOCAL_IP="$MY_IP"
NEUTRON_CONFIG_FILE="/etc/neutron/neutron.conf"
#L3_AGENT_CONFIG_FILE="/etc/neutron/l3_agent.ini"
PLUGIN_ML2_CONFIG_FILE="/etc/neutron/plugins/ml2/ml2_conf.ini"

# Configure the service with environment variables defined
sed -i -e "s#%NEUTRON_IDENTITY_URI%#${NEUTRON_IDENTITY_URI}#" \
    -e "s#%NEUTRON_SERVICE_TENANT_NAME%#${NEUTRON_SERVICE_TENANT_NAME}#" \
    -e "s#%NEUTRON_SERVICE_USER%#${NEUTRON_SERVICE_USER}#" \
    -e "s#%NEUTRON_SERVICE_PASS%#${NEUTRON_SERVICE_PASS}#" \
    -e "s#%NEUTRON_RABBITMQ_HOST%#${NEUTRON_RABBITMQ_HOST}#" \
    -e "s#%NEUTRON_RABBITMQ_USER%#${NEUTRON_RABBITMQ_USER}#" \
    -e "s#%NEUTRON_RABBITMQ_PASS%#${NEUTRON_RABBITMQ_PASS}#" \
        "$NEUTRON_CONFIG_FILE"

sed -i -e "s#%NEUTRON_EXTERNAL_NETWORKS%#${NEUTRON_EXTERNAL_NETWORKS}#" \
    -e "s#%TUNNEL_LOCAL_IP%#${TUNNEL_LOCAL_IP}#" \
    -e "s#%NEUTRON_BRIDGE_MAPPINGS%#${NEUTRON_BRIDGE_MAPPINGS}#" \
        "$PLUGIN_ML2_CONFIG_FILE"

# Start OVS switch
/etc/init.d/openvswitch-switch start

# Create external bridge
ovs-vsctl br-exists br-ex && ovs-vsctl del-br br-ex
ovs-vsctl add-br br-ex

# Start OVS agent
/usr/bin/python /usr/bin/neutron-openvswitch-agent \
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini \
    --config-file=/etc/neutron/neutron.conf &

# Start the service
neutron-l3-agent \
    --config-file=/etc/neutron/neutron.conf \
    --config-file=/etc/neutron/l3_agent.ini
