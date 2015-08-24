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
NEUTRON_DB_HOST="${NEUTRON_DB_HOST:-localhost}"
NEUTRON_DB_USER="${NEUTRON_DB_USER:-neutron}"
#NEUTRON_DB_PASS
NEUTRON_NOVA_URL="${NEUTRON_NOVA_URL:-http://127.0.0.1:8774/v2}"
NEUTRON_IDENTITY_URI="${NEUTRON_IDENTITY_URI:-http://127.0.0.1:35357}"
NEUTRON_SERVICE_TENANT_NAME="${NEUTRON_SERVICE_TENANT_NAME:-service}"
NEUTRON_SERVICE_USER="${NEUTRON_SERVICE_USER:-neutron}"
#NEUTRON_SERVICE_PASS
NOVA_AUTH_URL="${NOVA_AUTH_URL:-http://127.0.0.1:35357}"
NOVA_SERVICE_TENANT_NAME="${NOVA_SERVICE_TENANT_NAME:-service}"
NOVA_SERVICE_USER="${NOVA_SERVICE_USER:-neutron}"
#NOVA_SERVICE_PASS
NEUTRON_RABBITMQ_HOST="${NEUTRON_RABBITMQ_HOST:-localhost}"
NEUTRON_RABBITMQ_USER="${NEUTRON_RABBITMQ_USER:-guest}"
NEUTRON_RABBITMQ_PASS="${NEUTRON_RABBITMQ_PASS:-guest}"
NEUTRON_EXTERNAL_NETWORKS="${NEUTRON_EXTERNAL_NETWORKS:-external}"
NEUTRON_BRIDGE_MAPPINGS="${NEUTRON_BRIDGE_MAPPINGS:-external:br-ex}"


MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
TUNNEL_LOCAL_IP="$MY_IP"
DATABASE_CONNECTION=\
"mysql://${NEUTRON_DB_USER}:${NEUTRON_DB_PASS}@${NEUTRON_DB_HOST}/neutron"
NEUTRON_CONFIG_FILE="/etc/neutron/neutron.conf"
PLUGIN_ML2_CONFIG_FILE="/etc/neutron/plugins/ml2/ml2_conf.ini"

# Configure the service with environment variables defined
sed -i "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_NOVA_URL%#${NEUTRON_NOVA_URL}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_IDENTITY_URI%#${NEUTRON_IDENTITY_URI}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_TENANT_NAME%#${NEUTRON_SERVICE_TENANT_NAME}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_USER%#${NEUTRON_SERVICE_USER}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_SERVICE_PASS%#${NEUTRON_SERVICE_PASS}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NOVA_AUTH_URL%#${NOVA_AUTH_URL}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_TENANT_NAME%#${NOVA_SERVICE_TENANT_NAME}#" \
    "$NEUTRON_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_USER%#${NOVA_SERVICE_USER}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NOVA_SERVICE_PASS%#${NOVA_SERVICE_PASS}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_HOST%#${NEUTRON_RABBITMQ_HOST}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_USER%#${NEUTRON_RABBITMQ_USER}#" "$NEUTRON_CONFIG_FILE"
sed -i "s#%NEUTRON_RABBITMQ_PASS%#${NEUTRON_RABBITMQ_PASS}#" "$NEUTRON_CONFIG_FILE"

sed -i "s#%NEUTRON_EXTERNAL_NETWORKS%#${NEUTRON_EXTERNAL_NETWORKS}#" \
    "$PLUGIN_ML2_CONFIG_FILE"
sed -i "s#%TUNNEL_LOCAL_IP%#${TUNNEL_LOCAL_IP}#" "$PLUGIN_ML2_CONFIG_FILE"
sed -i "s#%NEUTRON_BRIDGE_MAPPINGS%#${NEUTRON_BRIDGE_MAPPINGS}#" \
    "$PLUGIN_ML2_CONFIG_FILE"

# Migrate neutron database
sudo -u neutron neutron-db-manage --config-file /etc/neutron/neutron.conf \
    upgrade head

# Start the service
neutron-server \
    --config-file=/etc/neutron/neutron.conf \
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini
