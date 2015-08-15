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
NOBA_DB_HOST="${NOBA_DB_HOST:-localhost}"
NOBA_DB_USER="${NOBA_DB_USER:-glance}"
#NOBA_DB_PASS
GLANCE_REGISTRY_HOST="${GLANCE_REGISTRY_HOST:-localhost}"
GLANCE_RABBITMQ_HOST="${GLANCE_RABBITMQ_HOST:-localhost}"
GLANCE_RABBITMQ_USER="${GLANCE_RABBITMQ_USER:-guest}"
GLANCE_RABBITMQ_PASS="${GLANCE_RABBITMQ_USER:-guest}"
#GLANCE_IDENTITY_URI
GLANCE_SERVICE_TENANT_NAME=${GLANCE_SERVICE_TENANT_NAME:-service}
GLANCE_SERVICE_USER=${GLANCE_SERVICE_USER:-glance}
#GLANCE_SERVICE_PASSWORD

DATABASE_CONNECTION=\
"mysql://${NOBA_DB_USER}:${NOBA_DB_PASS}@${NOBA_DB_HOST}/nova"
CONFIG_FILE="/etc/nova/nova.conf"

# Configure the service with environment variables defined
sed -i "s#%GLANCE_REGISTRY_HOST%#${GLANCE_REGISTRY_HOST}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_RABBITMQ_HOST%#${GLANCE_RABBITMQ_HOST}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_RABBITMQ_USER%#${GLANCE_RABBITMQ_USER}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_RABBITMQ_PASS%#${GLANCE_RABBITMQ_PASS}#" "$CONFIG_FILE"
sed -i "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_IDENTITY_URI%#${GLANCE_IDENTITY_URI}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SERVICE_TENANT_NAME%#${GLANCE_SERVICE_TENANT_NAME}#" \
    "$CONFIG_FILE"
sed -i "s#%GLANCE_SERVICE_USER%#${GLANCE_SERVICE_USER}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SERVICE_PASS%#${GLANCE_SERVICE_PASS}#" "$CONFIG_FILE"

# Migrate nova database
sudo -u nova nova-manage -v db sync

# Start the service
glance-api
