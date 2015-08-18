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
GLANCE_DB_HOST="${GLANCE_DB_HOST:-localhost}"
GLANCE_DB_USER="${GLANCE_DB_USER:-glance}"
#GLANCE_DB_PASS
GLANCE_REGISTRY_HOST="${GLANCE_REGISTRY_HOST:-localhost}"
GLANCE_RABBITMQ_HOST="${GLANCE_RABBITMQ_HOST:-localhost}"
GLANCE_RABBITMQ_USER="${GLANCE_RABBITMQ_USER:-guest}"
GLANCE_RABBITMQ_PASS="${GLANCE_RABBITMQ_USER:-guest}"
#GLANCE_IDENTITY_URI
GLANCE_SERVICE_TENANT_NAME=${GLANCE_SERVICE_TENANT_NAME:-service}
GLANCE_SERVICE_USER=${GLANCE_SERVICE_USER:-glance}
#GLANCE_SERVICE_PASSWORD
GLANCE_USE_SWIFT="${GLANCE_USE_SWIFT:-false}"
GLANCE_SWIFT_AUTH_ADDR="${GLANCE_SWIFT_AUTH_ADDR:-http://127.0.0.1:5000/v2.0/}"
GLANCE_SWIFT_TENANT_NAME="${GLANCE_SWIFT_TENANT_NAME:-glance}"
GLANCE_SWIFT_USER="${GLANCE_SWIFT_USER:-service:glance}"
GLANCE_SWIFT_PASS="${GLANCE_SWIFT_PASS:-}"
GLANCE_SWIFT_CONTAINER="${GLANCE_SWIFT_CONTAINER:-glance}"

if [ "$GLANCE_USE_SWIFT" == "true" ]; then
    GLANCE_SWIFT_STORE="glance.store.swift.Store,"
    GLANCE_DEFAULT_STORE="swift"
else
    GLANCE_SWIFT_STORE=""
    GLANCE_DEFAULT_STORE="file"
fi

DATABASE_CONNECTION=\
"mysql://${GLANCE_DB_USER}:${GLANCE_DB_PASS}@${GLANCE_DB_HOST}/glance"
CONFIG_FILE="/etc/glance/glance-api.conf"

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

sed -i "s#%GLANCE_SWIFT_AUTH_ADDR%#${GLANCE_SWIFT_AUTH_ADDR}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SWIFT_TENANT_NAME%#${GLANCE_SWIFT_TENANT_NAME}#" \
    "$CONFIG_FILE"
sed -i "s#%GLANCE_SWIFT_USER%#${GLANCE_SWIFT_USER}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SWIFT_PASS%#${GLANCE_SWIFT_PASS}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SWIFT_CONTAINER%#${GLANCE_SWIFT_CONTAINER}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_SWIFT_STORE%#${GLANCE_SWIFT_STORE}#" "$CONFIG_FILE"
sed -i "s#%GLANCE_DEFAULT_STORE%#${GLANCE_DEFAULT_STORE}#" "$CONFIG_FILE"

# Start the service
glance-api
