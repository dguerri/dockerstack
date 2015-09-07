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
GLANCE_DB_HOST="${GLANCE_DB_HOST:-localhost}"
GLANCE_DB_USER="${GLANCE_DB_USER:-glance}"
#GLANCE_DB_PASS
GLANCE_RABBITMQ_HOST="${GLANCE_RABBITMQ_HOST:-localhost}"
GLANCE_RABBITMQ_USER="${GLANCE_RABBITMQ_USER:-guest}"
GLANCE_RABBITMQ_PASS="${GLANCE_RABBITMQ_USER:-guest}"
#GLANCE_IDENTITY_URI
GLANCE_SERVICE_TENANT_NAME=${GLANCE_SERVICE_TENANT_NAME:-service}
GLANCE_SERVICE_USER=${GLANCE_SERVICE_USER:-glance}
#GLANCE_SERVICE_PASSWORD

DATABASE_CONNECTION=\
"mysql://${GLANCE_DB_USER}:${GLANCE_DB_PASS}@${GLANCE_DB_HOST}/glance"
CONFIG_FILE="/etc/glance/glance-registry.conf"

# Configure the service with environment variables defined
sed -i -e "s#%GLANCE_RABBITMQ_HOST%#${GLANCE_RABBITMQ_HOST}#" \
    -e "s#%GLANCE_RABBITMQ_USER%#${GLANCE_RABBITMQ_USER}#" \
    -e "s#%GLANCE_RABBITMQ_PASS%#${GLANCE_RABBITMQ_PASS}#" \
    -e "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" \
    -e "s#%GLANCE_IDENTITY_URI%#${GLANCE_IDENTITY_URI}#" \
    -e "s#%GLANCE_SERVICE_TENANT_NAME%#${GLANCE_SERVICE_TENANT_NAME}#" \
    -e "s#%GLANCE_SERVICE_USER%#${GLANCE_SERVICE_USER}#" \
    -e "s#%GLANCE_SERVICE_PASS%#${GLANCE_SERVICE_PASS}#" "$CONFIG_FILE"

# Migrate glance database
sudo -u glance glance-manage -v db_sync

# Start the service
glance-registry
