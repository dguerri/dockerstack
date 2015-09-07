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
IRONIC_NOTIFICATIONS="${IRONIC_NOTIFICATIONS:-false}"

IRONIC_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
DATABASE_CONNECTION=\
"mysql://${IRONIC_DB_USER}:${IRONIC_DB_PASS}@${IRONIC_DB_HOST}/ironic"
CONFIG_FILE="/etc/ironic/ironic.conf"

if [ "$IRONIC_NOTIFICATIONS" == "true" -o \
     "$IRONIC_NOTIFICATIONS" == "True" ]; then
    NOTIFICATION_DRIVER="messagingv2"
    SEND_SENSOR_DATA="true"
else
    # Turn off notifications
    NOTIFICATION_DRIVER="noop"
    SEND_SENSOR_DATA="false"
fi


# Configure the service with environment variables defined
sed -i -e "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" \
    -e "s#%IRONIC_MEMCACHED_SERVERS%#${IRONIC_MEMCACHED_SERVERS}#" \
    -e "s#%IRONIC_MY_IP%#${IRONIC_MY_IP}#" \
    -e "s#%IRONIC_CLEAN_NODE%#${IRONIC_CLEAN_NODE}#" \
    -e "s#%IRONIC_SWIFT_TEMP_URL_KEY%#${IRONIC_SWIFT_TEMP_URL_KEY}#" \
    -e "s#%IRONIC_SWIFT_ENDPOINT_URL%#${IRONIC_SWIFT_ENDPOINT_URL}#" \
    -e "s#%IRONIC_SWIFT_ACCOUNT%#${IRONIC_SWIFT_ACCOUNT}#" \
    -e "s#%IRONIC_SWIFT_CONTAINER%#${IRONIC_SWIFT_CONTAINER}#" \
    -e "s#%IRONIC_GLANCE_API_URLS%#${IRONIC_GLANCE_API_URLS}#" \
    -e "s#%IRONIC_IDENTITY_URI%#${IRONIC_IDENTITY_URI}#" \
    -e "s#%IRONIC_SERVICE_TENANT_NAME%#${IRONIC_SERVICE_TENANT_NAME}#" \
    -e "s#%IRONIC_SERVICE_USER%#${IRONIC_SERVICE_USER}#" \
    -e "s#%IRONIC_SERVICE_PASS%#${IRONIC_SERVICE_PASS}#" \
    -e "s#%IRONIC_NEUTRON_SERVER_URL%#${IRONIC_NEUTRON_SERVER_URL}#" \
    -e "s#%IRONIC_RABBITMQ_HOST%#${IRONIC_RABBITMQ_HOST}#" \
    -e "s#%IRONIC_RABBITMQ_USER%#${IRONIC_RABBITMQ_USER}#" \
    -e "s#%IRONIC_RABBITMQ_PASS%#${IRONIC_RABBITMQ_PASS}#" \
    -e "s#%NOTIFICATION_DRIVER%#${NOTIFICATION_DRIVER}#" \
    -e "s#%SEND_SENSOR_DATA%#${SEND_SENSOR_DATA}#" "$CONFIG_FILE"

# Migrate ironic database
sudo -u ironic ironic-dbsync -v upgrade

# Start the service
ironic-api
