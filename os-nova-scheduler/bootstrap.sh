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
NOVA_DB_HOST="${NOVA_DB_HOST:-localhost}"
NOVA_DB_USER="${NOVA_DB_USER:-nova}"
#NOVA_DB_PASS
NOVA_RABBITMQ_HOST="${NOVA_RABBITMQ_HOST:-localhost}"
NOVA_RABBITMQ_USER="${NOVA_RABBITMQ_USER:-nova}"
#NOVA_RABBITMQ_PASS
NOVA_IDENTITY_URI="${NOVA_IDENTITY_URI:-http://127.0.0.1:35357}"
NOVA_SERVICE_TENANT_NAME=${NOVA_SERVICE_TENANT_NAME:-service}
NOVA_SERVICE_USER=${NOVA_SERVICE_USER:-nova}
#NOVA_SERVICE_PASS
NOVA_MEMCACHED_SERVERS="${NOVA_MEMCACHED_SERVERS:-}"
NOVA_USE_IRONIC="${NOVA_USE_IRONIC:-false}"

NOVA_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
DATABASE_CONNECTION=\
"mysql://${NOVA_DB_USER}:${NOVA_DB_PASS}@${NOVA_DB_HOST}/nova"
CONFIG_FILE="/etc/nova/nova.conf"
if [ "$NOVA_USE_IRONIC" == "true" -o "$NOVA_USE_IRONIC" == "True" ]; then
    SCHEDULER_HOST_MANAGER=\
"nova.scheduler.ironic_host_manager.IronicHostManager"
    SCHEDULER_USE_BAREMETAL_FILTERS=True
    SCHEDULER_TRACKS_INSTANCE_CHANGES=False
    RAM_ALLOCATION_RATIO="1.0"
else
    SCHEDULER_HOST_MANAGER="nova.scheduler.host_manager.HostManager"
    SCHEDULER_USE_BAREMETAL_FILTERS=False
    SCHEDULER_TRACKS_INSTANCE_CHANGES=True
    RAM_ALLOCATION_RATIO="1.5"

    /etc/init.d/libvirt-bin start
fi

# Configure the service with environment variables defined
sed -i "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" "$CONFIG_FILE"
sed -i "s#%NOVA_MY_IP%#${NOVA_MY_IP}#" "$CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_HOST%#${NOVA_RABBITMQ_HOST}#" "$CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_USER%#${NOVA_RABBITMQ_USER}#" "$CONFIG_FILE"
sed -i "s#%NOVA_RABBITMQ_PASS%#${NOVA_RABBITMQ_PASS}#" "$CONFIG_FILE"
sed -i "s#%NOVA_IDENTITY_URI%#${NOVA_IDENTITY_URI}#" "$CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_TENANT_NAME%#${NOVA_SERVICE_TENANT_NAME}#" \
    "$CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_USER%#${NOVA_SERVICE_USER}#" "$CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_PASS%#${NOVA_SERVICE_PASS}#" "$CONFIG_FILE"
sed -i "s#%NOVA_MEMCACHED_SERVERS%#${NOVA_MEMCACHED_SERVERS}#" "$CONFIG_FILE"
sed -i "s#%SCHEDULER_HOST_MANAGER%#${SCHEDULER_HOST_MANAGER}#" "$CONFIG_FILE"
sed -i \
    "s#%SCHEDULER_USE_BAREMETAL_FILTERS%#${SCHEDULER_USE_BAREMETAL_FILTERS}#" \
    "$CONFIG_FILE"
sed -i \
"s#%SCHEDULER_TRACKS_INSTANCE_CHANGES%#${SCHEDULER_TRACKS_INSTANCE_CHANGES}#" \
    "$CONFIG_FILE"
sed -i "s#%RAM_ALLOCATION_RATIO%#${RAM_ALLOCATION_RATIO}#" "$CONFIG_FILE"

# Start the service
nova-scheduler
