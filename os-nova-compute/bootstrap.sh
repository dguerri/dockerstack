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
NOVA_RABBITMQ_HOST="${NOVA_RABBITMQ_HOST:-localhost}"
NOVA_RABBITMQ_USER="${NOVA_RABBITMQ_USER:-nova}"
#NOVA_RABBITMQ_PASS
NOVA_MEMCACHED_SERVERS="${NOVA_MEMCACHED_SERVERS:-}"
NOVA_IDENTITY_URI="${NOVA_IDENTITY_URI:-http://127.0.0.1:35357}"
NOVA_SERVICE_TENANT_NAME=${NOVA_SERVICE_TENANT_NAME:-service}
NOVA_SERVICE_USER=${NOVA_SERVICE_USER:-nova}
#NOVA_SERVICE_PASS
NOVA_GLANCE_API_URLS=${NOVA_GLANCE_API_URLS:-http://127.0.0.1:9292}
NOVA_IRONIC_API_ENDPOINT=${NOVA_IRONIC_API_ENDPOINT:-http://127.0.0.1:6385/v1}
NOVA_NEUTRON_SERVER_URL=${NOVA_NEUTRON_SERVER_URL:-http://127.0.0.1:9696/}
NOVA_NEUTRON_AUTH_URI="${NOVA_NEUTRON_AUTH_URI:-http://127.0.0.1:5000/v2.0}"
NOVA_NEUTRON_SERVICE_USER="${NOVA_NEUTRON_SERVICE_USER:-neutron}"
#NOVA_NEUTRON_SERVICE_PASS
NOVA_NEUTRON_SERVICE_TENANT_NAME="${NOVA_NEUTRON_SERVICE_TENANT_NAME:-service}"
NOVA_USE_IRONIC="${NOVA_USE_IRONIC:-false}"
NOVA_IRONIC_SERVICE_USER="${NOVA_IRONIC_SERVICE_USER:-ironic}"
NOVA_IRONIC_SERVICE_PASS="${NOVA_IRONIC_SERVICE_PASS:-}"
NOVA_IRONIC_AUTH_URI="${NOVA_IRONIC_AUTH_URI:-http://127.0.0.1:5000/v2.0}"
NOVA_IRONIC_SERVICE_TENANT_NAME="${NOVA_IRONIC_SERVICE_TENANT_NAME:-service}"
NOVA_NOTIFICATIONS="${NOVA_NOTIFICATIONS:-false}"
NOVA_NOTIFY_ON_STATE_CHANGE="${NOVA_NOTIFY_ON_STATE_CHANGE:-vm_state}"
NOVA_VIRT_TYPE="${NOVA_VIRT_TYPE:-kvm}"
NEUTRON_IDENTITY_URI="${NEUTRON_IDENTITY_URI:-http://127.0.0.1:35357}"
NEUTRON_SERVICE_TENANT_NAME="${NEUTRON_SERVICE_TENANT_NAME:-service}"
NEUTRON_SERVICE_USER="${NEUTRON_SERVICE_USER:-neutron}"
#NEUTRON_SERVICE_PASS
NEUTRON_RABBITMQ_HOST="${NEUTRON_RABBITMQ_HOST:-localhost}"
NEUTRON_RABBITMQ_USER="${NEUTRON_RABBITMQ_USER:-guest}"
NEUTRON_RABBITMQ_PASS="${NEUTRON_RABBITMQ_PASS:-guest}"
NEUTRON_BRIDGE_MAPPINGS="${NEUTRON_BRIDGE_MAPPINGS:-external:br-ex}"

MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
#MY_SUBNET="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $4}')"
#MY_GW=$(ip route show | awk '/default/ {print $3}')
TUNNEL_LOCAL_IP="$MY_IP"

NOVA_CONFIG_FILE="/etc/nova/nova.conf"
NOVA_COMPUTE_CONFIG_FILE="/etc/nova/nova-compute.conf"
NEUTRON_CONFIG_FILE="/etc/neutron/neutron.conf"
PLUGIN_ML2_CONFIG_FILE="/etc/neutron/plugins/ml2/ml2_conf.ini"

if [ "$NOVA_USE_IRONIC" == "true" ] || [ "$NOVA_USE_IRONIC" == "True" ]; then
    FIREWALL_DRIVER="nova.virt.firewall.NoopFirewallDriver"
    COMPUTE_DRIVER="nova.virt.ironic.IronicDriver"
    COMPUTE_MANAGER="ironic.nova.compute.manager.ClusteredComputeManager"
    RESERVED_HOST_MEMORY_MB=0
else
    FIREWALL_DRIVER=""
    COMPUTE_DRIVER="libvirt.LibvirtDriver"
    COMPUTE_MANAGER="nova.compute.manager.ComputeManager"
    RESERVED_HOST_MEMORY_MB=512

    # Enable nbd support
    modprobe nbd nbds_max=30
    for ((i=0;i<30;i++)); do
        if [ ! -b /dev/nbd$i ]; then
            mknod /dev/nbd$i b 43 $((16*i))
        fi
    done

    # Enable KVM support
    if [ "$NOVA_VIRT_TYPE" == "kvm" ]; then
        modprobe kvm
        chown root:kvm /dev/kvm
        chmod 660 /dev/kvm
    fi

    /etc/init.d/libvirt-bin start
fi

if [ "$NOVA_NOTIFICATIONS" == "true" ] \
    || [ "$NOVA_NOTIFICATIONS" == "True" ]; then
     NOTIFICATION_DRIVER="messagingv2"
else
    # Turn off notifications
    NOTIFICATION_DRIVER="noop"
    NOVA_NOTIFY_ON_STATE_CHANGE="None"
fi

# Configure the service with environment variables defined
sed -i -e "s#%NOVA_MY_IP%#${MY_IP}#" \
    -e "s#%NOVA_RABBITMQ_HOST%#${NOVA_RABBITMQ_HOST}#" \
    -e "s#%NOVA_RABBITMQ_USER%#${NOVA_RABBITMQ_USER}#" \
    -e "s#%NOVA_RABBITMQ_PASS%#${NOVA_RABBITMQ_PASS}#" \
    -e "s#%NOVA_IDENTITY_URI%#${NOVA_IDENTITY_URI}#" \
    -e "s#%NOVA_SERVICE_TENANT_NAME%#${NOVA_SERVICE_TENANT_NAME}#" \
    -e "s#%NOVA_SERVICE_USER%#${NOVA_SERVICE_USER}#" \
    -e "s#%NOVA_SERVICE_PASS%#${NOVA_SERVICE_PASS}#" \
    -e "s#%NOVA_GLANCE_API_URLS%#${NOVA_GLANCE_API_URLS}#" \
    -e "s#%COMPUTE_DRIVER%#${COMPUTE_DRIVER}#" \
    -e "s#%NOVA_NOTIFY_ON_STATE_CHANGE%#${NOVA_NOTIFY_ON_STATE_CHANGE}#" \
    -e "s#%NOTIFICATION_DRIVER%#${NOTIFICATION_DRIVER}#" \
    -e "s#%NOVA_NEUTRON_SERVER_URL%#${NOVA_NEUTRON_SERVER_URL}#" \
    -e "s#%NOVA_NEUTRON_AUTH_URI%#${NOVA_NEUTRON_AUTH_URI}#" \
    -e "s#%NOVA_NEUTRON_SERVICE_USER%#${NOVA_NEUTRON_SERVICE_USER}#" \
    -e "s#%NOVA_NEUTRON_SERVICE_PASS%#${NOVA_NEUTRON_SERVICE_PASS}#" \
    -e "s#%NOVA_NEUTRON_SERVICE_TENANT_NAME%#${NOVA_NEUTRON_SERVICE_TENANT_NAME}#" \
    -e "s#%NOVA_IRONIC_API_ENDPOINT%#${NOVA_IRONIC_API_ENDPOINT}#" \
    -e "s#%NOVA_IRONIC_SERVICE_USER%#${NOVA_IRONIC_SERVICE_USER}#" \
    -e "s#%NOVA_IRONIC_SERVICE_PASS%#${NOVA_IRONIC_SERVICE_PASS}#" \
    -e "s#%NOVA_IRONIC_AUTH_URI%#${NOVA_IRONIC_AUTH_URI}#" \
    -e "s#%NOVA_IRONIC_SERVICE_TENANT_NAME%#${NOVA_IRONIC_SERVICE_TENANT_NAME}#" \
    -e "s#%NOVA_MEMCACHED_SERVERS%#${NOVA_MEMCACHED_SERVERS}#" \
    -e "s#%FIREWALL_DRIVER%#${FIREWALL_DRIVER}#" \
    -e "s#%COMPUTE_DRIVER%#${COMPUTE_DRIVER}#" \
    -e "s#%COMPUTE_MANAGER%#${COMPUTE_MANAGER}#" \
    -e "s#%RESERVED_HOST_MEMORY_MB%#${RESERVED_HOST_MEMORY_MB}#" \
        "$NOVA_CONFIG_FILE"

sed -i -e "s#%COMPUTE_DRIVER%#${COMPUTE_DRIVER}#" \
    -e "s#%NOVA_VIRT_TYPE%#${NOVA_VIRT_TYPE}#" \
        "$NOVA_COMPUTE_CONFIG_FILE"

sed -i -e "s#%NEUTRON_IDENTITY_URI%#${NEUTRON_IDENTITY_URI}#" \
    -e "s#%NEUTRON_SERVICE_TENANT_NAME%#${NEUTRON_SERVICE_TENANT_NAME}#" \
    -e "s#%NEUTRON_SERVICE_USER%#${NEUTRON_SERVICE_USER}#" \
    -e "s#%NEUTRON_SERVICE_PASS%#${NEUTRON_SERVICE_PASS}#" \
    -e "s#%NEUTRON_RABBITMQ_HOST%#${NEUTRON_RABBITMQ_HOST}#" \
    -e "s#%NEUTRON_RABBITMQ_USER%#${NEUTRON_RABBITMQ_USER}#" \
    -e "s#%NEUTRON_RABBITMQ_PASS%#${NEUTRON_RABBITMQ_PASS}#" \
        "$NEUTRON_CONFIG_FILE"

sed -i -e "s#%TUNNEL_LOCAL_IP%#${TUNNEL_LOCAL_IP}#" \
    -e "s#%NEUTRON_BRIDGE_MAPPINGS%#${NEUTRON_BRIDGE_MAPPINGS}#" \
        "$PLUGIN_ML2_CONFIG_FILE"

# Start OVS switch
/etc/init.d/openvswitch-switch start

# Configure br-ex, not really used
ovs-vsctl br-exists br-ex && ovs-vsctl del-br br-ex
ovs-vsctl add-br br-ex

# Start OVS agent
/usr/bin/python /usr/bin/neutron-openvswitch-agent \
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini \
    --config-file=/etc/neutron/neutron.conf &

# Start the service
nova-compute
