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
IRONIC_DB_HOST="${IRONIC_DB_HOST:-localhost}"
IRONIC_DB_USER="${IRONIC_DB_USER:-ironic}"
#IRONIC_DB_PASS
IRONIC_CLEAN_NODE="${IRONIC_CLEAN_NODE:-false}"
#IRONIC_SWIFT_TEMP_URL_KEY
#IRONIC_SWIFT_ENDPOINT_URL
#IRONIC_SWIFT_ACCOUNT
IRONIC_SWIFT_CONTAINER="${IRONIC_SWIFT_CONTAINER:-glance}"
IRONIC_GLANCE_API_URLS="${IRONIC_GLANCE_API_URLS:-http://127.0.0.1:9292}"
IRONIC_IDENTITY_URI="${IRONIC_IDENTITY_URI:-http://127.0.0.1:35357}"
IRONIC_SERVICE_TENANT_NAME="${IRONIC_SERVICE_TENANT_NAME:-service}"
IRONIC_SERVICE_USER="${IRONIC_SERVICE_USER:-ironic}"
#IRONIC_SERVICE_PASS
IRONIC_NEUTRON_SERVER_URL=\
"${IRONIC_NEUTRON_SERVER_URL:-http://127.0.0.1:9696}"
IRONIC_RABBITMQ_HOST="${IRONIC_RABBITMQ_HOST:-localhost}"
IRONIC_RABBITMQ_USER="${IRONIC_RABBITMQ_USER:-ironic}"
#IRONIC_RABBITMQ_PASS
IRONIC_MEMCACHED_SERVERS="${IRONIC_MEMCACHED_SERVERS:-}"

IRONIC_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
DATABASE_CONNECTION=\
"mysql://${IRONIC_DB_USER}:${IRONIC_DB_PASS}@${IRONIC_DB_HOST}/ironic"
CONFIG_FILE="/etc/ironic/ironic.conf"

# Configure the service with environment variables defined
sed -i "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_MEMCACHED_SERVERS%#${IRONIC_MEMCACHED_SERVERS}#" \
    "$CONFIG_FILE"
sed -i "s#%IRONIC_MY_IP%#${IRONIC_MY_IP}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_CLEAN_NODE%#${IRONIC_CLEAN_NODE}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_SWIFT_TEMP_URL_KEY%#${IRONIC_SWIFT_TEMP_URL_KEY}#" \
    "$CONFIG_FILE"
sed -i "s#%IRONIC_SWIFT_ENDPOINT_URL%#${IRONIC_SWIFT_ENDPOINT_URL}#" \
    "$CONFIG_FILE"
sed -i "s#%IRONIC_SWIFT_ACCOUNT%#${IRONIC_SWIFT_ACCOUNT}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_SWIFT_CONTAINER%#${IRONIC_SWIFT_CONTAINER}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_GLANCE_API_URLS%#${IRONIC_GLANCE_API_URLS}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_IDENTITY_URI%#${IRONIC_IDENTITY_URI}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_SERVICE_TENANT_NAME%#${IRONIC_SERVICE_TENANT_NAME}#" \
    "$CONFIG_FILE"
sed -i "s#%IRONIC_SERVICE_USER%#${IRONIC_SERVICE_USER}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_SERVICE_PASS%#${IRONIC_SERVICE_PASS}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_NEUTRON_SERVER_URL%#${IRONIC_NEUTRON_SERVER_URL}#" \
    "$CONFIG_FILE"
sed -i "s#%IRONIC_RABBITMQ_HOST%#${IRONIC_RABBITMQ_HOST}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_RABBITMQ_USER%#${IRONIC_RABBITMQ_USER}#" "$CONFIG_FILE"
sed -i "s#%IRONIC_RABBITMQ_PASS%#${IRONIC_RABBITMQ_PASS}#" "$CONFIG_FILE"

# Migrate ironic database
sudo -u ironic ironic-dbsync -v upgrade

# Start the service
ironic-api
