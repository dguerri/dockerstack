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
NOVA_RABBITMQ_HOST="${NOVA_RABBITMQ_HOST:-localhost}"
NOVA_RABBITMQ_USER="${NOVA_RABBITMQ_USER:-nova}"
#NOVA_RABBITMQ_PASS
NOVA_IDENTITY_URI="${NOVA_IDENTITY_URI:-http://127.0.0.1:35357}"
NOVA_SERVICE_TENANT_NAME=${NOVA_SERVICE_TENANT_NAME:-service}
NOVA_SERVICE_USER=${NOVA_SERVICE_USER:-nova}
#NOVA_SERVICE_PASS
NOVA_GLANCE_API_URLS=${NOVA_GLANCE_API_URLS:-http://127.0.0.1:9292}
NOVA_NEUTRON_SERVER_URL=${NOVA_NEUTRON_SERVER_URL:-http://127.0.0.1:9696/}
NOVA_IRONIC_API_ENDPOINT=${NOVA_IRONIC_API_ENDPOINT:-http://127.0.0.1:6385/v1}
NOVA_USE_IRONIC="${NOVA_USE_IRONIC:-false}"
NOVA_MEMCACHED_SERVERS="${NOVA_MEMCACHED_SERVERS:-}"

NOVA_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
NOVA_CONFIG_FILE="/etc/nova/nova.conf"
NOVA_COMPUTE_CONFIG_FILE="/etc/nova/nova-compute.conf"
if [ "$NOVA_USE_IRONIC" == "true" ]; then
    COMPUTE_DRIVER="nova.virt.ironic.IronicDriver"
else
    COMPUTE_DRIVER="libvirt.LibvirtDriver"
    /etc/init.d/libvirt-bin start
fi

# Configure the service with environment variables defined
sed -i "s#%NOVA_MY_IP%#${NOVA_MY_IP}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_HOST%#${NOVA_RABBITMQ_HOST}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_USER%#${NOVA_RABBITMQ_USER}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_PASS%#${NOVA_RABBITMQ_PASS}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_IDENTITY_URI%#${NOVA_IDENTITY_URI}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_TENANT_NAME%#${NOVA_SERVICE_TENANT_NAME}#" \
    "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_USER%#${NOVA_SERVICE_USER}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_PASS%#${NOVA_SERVICE_PASS}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_GLANCE_API_URLS%#${NOVA_GLANCE_API_URLS}#" "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_NEUTRON_SERVER_URL%#${NOVA_NEUTRON_SERVER_URL}#" \
    "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_IRONIC_API_ENDPOINT%#${NOVA_IRONIC_API_ENDPOINT}#" \
    "$NOVA_CONFIG_FILE"
sed -i "s#%NOVA_MEMCACHED_SERVERS%#${NOVA_MEMCACHED_SERVERS}#" \
    "$NOVA_CONFIG_FILE"
sed -i "s#%COMPUTE_DRIVER%#${COMPUTE_DRIVER}#" "$NOVA_COMPUTE_CONFIG_FILE"

# Start the service
nova-compute
