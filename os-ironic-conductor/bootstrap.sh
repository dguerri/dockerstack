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
IRONIC_AUTH_URI="${IRONIC_AUTH_URI:-http://127.0.0.1:5000}"
IRONIC_SERVICE_TENANT_NAME="${IRONIC_SERVICE_TENANT_NAME:-service}"
IRONIC_SERVICE_USER="${IRONIC_SERVICE_USER:-ironic}"
#IRONIC_SERVICE_PASS
IRONIC_NEUTRON_SERVER_URL=\
"${IRONIC_NEUTRON_SERVER_URL:-http://127.0.0.1:9696}"
IRONIC_RABBITMQ_HOST="${IRONIC_RABBITMQ_HOST:-localhost}"
IRONIC_RABBITMQ_USER="${IRONIC_RABBITMQ_USER:-ironic}"
#IRONIC_RABBITMQ_PASS
IRONIC_MEMCACHED_SERVERS="${IRONIC_MEMCACHED_SERVERS:-}"
IRONIC_TFTP_SERVER="${IRONIC_TFTP_SERVER:-\$my_ip}"
IRONIC_IPXE_HTTP_URL="${IRONIC_IPXE_HTTP_URL:-http://\$my_ip:8080}"
IRONIC_USE_IPXE="${IRONIC_USE_IPXE:-false}"
IRONIC_NOTIFICATIONS="${IRONIC_NOTIFICATIONS:-false}"

IRONIC_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
DATABASE_CONNECTION=\
"mysql://${IRONIC_DB_USER}:${IRONIC_DB_PASS}@${IRONIC_DB_HOST}/ironic"
if [ "$IRONIC_USE_IPXE" == "true" -o "$IRONIC_USE_IPXE" == "True" ]; then
    PXE_BOOTFILE_NAME="undionly.kpxe"
    PXE_CONFIG_TEMPLATE="\$pybasedir/drivers/modules/ipxe_config.template"
else
    PXE_BOOTFILE_NAME="pxelinux.0"
    PXE_CONFIG_TEMPLATE="\$pybasedir/drivers/modules/pxe_config.template"
fi
IRONIC_CONFIG_FILE="/etc/ironic/ironic.conf"
AGENT_TEMPLATE="/etc/ironic/agent_config.template"

if [ "$IRONIC_NOTIFICATIONS" == "true" -o \
     "$IRONIC_NOTIFICATIONS" == "True" ]; then
    NOTIFICATION_DRIVER="messagingv2"
    SEND_SENSOR_DATA="true"
else
    # Turn off ironic notification
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
    -e "s#%IRONIC_AUTH_URI%#${IRONIC_AUTH_URI}#" \
    -e "s#%IRONIC_SERVICE_TENANT_NAME%#${IRONIC_SERVICE_TENANT_NAME}#" \
    -e "s#%IRONIC_SERVICE_USER%#${IRONIC_SERVICE_USER}#" \
    -e "s#%IRONIC_SERVICE_PASS%#${IRONIC_SERVICE_PASS}#" \
    -e "s#%IRONIC_NEUTRON_SERVER_URL%#${IRONIC_NEUTRON_SERVER_URL}#" \
    -e "s#%IRONIC_RABBITMQ_HOST%#${IRONIC_RABBITMQ_HOST}#" \
    -e "s#%IRONIC_RABBITMQ_USER%#${IRONIC_RABBITMQ_USER}#" \
    -e "s#%IRONIC_RABBITMQ_PASS%#${IRONIC_RABBITMQ_PASS}#" \
    -e "s#%IRONIC_TFTP_SERVER%#${IRONIC_TFTP_SERVER}#" \
    -e "s#%IRONIC_IPXE_HTTP_URL%#${IRONIC_IPXE_HTTP_URL}#" \
    -e "s#%PXE_BOOTFILE_NAME%#${PXE_BOOTFILE_NAME}#" \
    -e "s#%PXE_CONFIG_TEMPLATE%#${PXE_CONFIG_TEMPLATE}#" \
    -e "s#%IRONIC_USE_IPXE%#${IRONIC_USE_IPXE}#" \
    -e "s#%NOTIFICATION_DRIVER%#${NOTIFICATION_DRIVER}#" \
    -e "s#%SEND_SENSOR_DATA%#${SEND_SENSOR_DATA}#" "$IRONIC_CONFIG_FILE"

sed -i "s#%IRONIC_IPXE_HTTP_URL%#${IRONIC_IPXE_HTTP_URL}#" "$AGENT_TEMPLATE"

# Migrate ironic database
sudo -u ironic ironic-dbsync -v upgrade

# Create missing directories, if needed
if [ ! -d  /pxe/tftpboot ]; then
    mkdir -p /pxe/tftpboot
fi
chown -R ironic /pxe/tftpboot

if [ ! -d  /pxe/httpboot ]; then
    mkdir -p /pxe/httpboot
fi
chown -R ironic /pxe/httpboot

# Temporary. This should be copied over automatically...
cp /usr/lib/python2.7/dist-packages/ironic/drivers/modules/boot.ipxe \
    /pxe/httpboot/

# Start the service
ironic-conductor
