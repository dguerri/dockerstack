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
sed -i -e "s#%GLANCE_REGISTRY_HOST%#${GLANCE_REGISTRY_HOST}#" \
    -e "s#%GLANCE_RABBITMQ_HOST%#${GLANCE_RABBITMQ_HOST}#" \
    -e "s#%GLANCE_RABBITMQ_USER%#${GLANCE_RABBITMQ_USER}#" \
    -e "s#%GLANCE_RABBITMQ_PASS%#${GLANCE_RABBITMQ_PASS}#" \
    -e "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" \
    -e "s#%GLANCE_IDENTITY_URI%#${GLANCE_IDENTITY_URI}#" \
    -e "s#%GLANCE_SERVICE_TENANT_NAME%#${GLANCE_SERVICE_TENANT_NAME}#" \
    -e "s#%GLANCE_SERVICE_USER%#${GLANCE_SERVICE_USER}#" \
    -e "s#%GLANCE_SERVICE_PASS%#${GLANCE_SERVICE_PASS}#" \
    -e "s#%GLANCE_SWIFT_AUTH_ADDR%#${GLANCE_SWIFT_AUTH_ADDR}#" \
    -e "s#%GLANCE_SWIFT_TENANT_NAME%#${GLANCE_SWIFT_TENANT_NAME}#" \
    -e "s#%GLANCE_SWIFT_USER%#${GLANCE_SWIFT_USER}#" \
    -e "s#%GLANCE_SWIFT_PASS%#${GLANCE_SWIFT_PASS}#" \
    -e "s#%GLANCE_SWIFT_CONTAINER%#${GLANCE_SWIFT_CONTAINER}#" \
    -e "s#%GLANCE_SWIFT_STORE%#${GLANCE_SWIFT_STORE}#" \
    -e "s#%GLANCE_DEFAULT_STORE%#${GLANCE_DEFAULT_STORE}#" "$CONFIG_FILE"

# Start the service
glance-api
