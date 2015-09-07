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
SWIFT_IDENTITY_URI="${SWIFT_IDENTITY_URI:-http://127.0.0.1:35357}"
SWIFT_SERVICE_TENANT_NAME=${SWIFT_SERVICE_TENANT_NAME:-service}
SWIFT_SERVICE_USER=${SWIFT_SERVICE_USER:-swift}
#SWIFT_SERVICE_PASS
SWIFT_MEMCACHED_SERVERS="${SWIFT_MEMCACHED_SERVERS:-}"
SWIFT_HASH_PATH_PREFIX="${SWIFT_HASH_PATH_PREFIX:-default}"
SWIFT_HASH_PATH_SUFFIX="${SWIFT_HASH_PATH_SUFFIX:-default}"

SWIFT_ACCOUNT_BLOCK_DEVICES=(${SWIFT_ACCOUNT_BLOCK_DEVICES//,/ })
SWIFT_CONTAINER_BLOCK_DEVICES=(${SWIFT_CONTAINER_BLOCK_DEVICES//,/ })
SWIFT_OBJECT_BLOCK_DEVICES=(${SWIFT_OBJECT_BLOCK_DEVICES//,/ })
SWIFT_PART_POWER="${SWIFT_PART_POWER:-10}"
SWIFT_REPLICA="${SWIFT_REPLICA:-3}"
SWIFT_MIN_PART_HOURS="${SWIFT_MIN_PART_HOURS:-1}"

if [ -z "$SWIFT_MEMCACHED_SERVERS" ]; then
    SWIFT_CACHE=""
else
    SWIFT_CACHE="cache"
fi
SWIFT_CONFIG_FILE="/etc/swift/swift.conf"
PROXY_CONFIG_FILE="/etc/swift/proxy-server.conf"

# Configure the service with environment variables defined
sed -i -e "s#%SWIFT_IDENTITY_URI%#${SWIFT_IDENTITY_URI}#" \
    -e "s#%SWIFT_SERVICE_TENANT_NAME%#${SWIFT_SERVICE_TENANT_NAME}#" \
    -e "s#%SWIFT_SERVICE_USER%#${SWIFT_SERVICE_USER}#" \
    -e "s#%SWIFT_SERVICE_PASS%#${SWIFT_SERVICE_PASS}#" \
    -e "s#%SWIFT_MEMCACHED_SERVERS%#${SWIFT_MEMCACHED_SERVERS}#" \
    -e "s#%SWIFT_CACHE%#${SWIFT_CACHE}#" "$PROXY_CONFIG_FILE"

sed -i -e "s#%SWIFT_HASH_PATH_PREFIX%#${SWIFT_HASH_PATH_PREFIX}#" \
    -e "s#%SWIFT_HASH_PATH_SUFFIX%#${SWIFT_HASH_PATH_SUFFIX}#" \
        "$SWIFT_CONFIG_FILE"

# Create rings, if needed
setup_ring() {
    local name="$1"
    local devices=("${!2}")

    if [ ! -f "/etc/swift/rings/$name.builder" ]; then
        swift-ring-builder "/etc/swift/rings/$name.builder" create \
            "$SWIFT_PART_POWER" "$SWIFT_REPLICA" "$SWIFT_MIN_PART_HOURS"
        for d_w in "${devices[@]}"; do
            d_w_array=(${d_w//;/})
            device="${d_w_array[0]}"
            weight="${d_w_array[1]:-100}"
            swift-ring-builder "/etc/swift/rings/$name.builder" add \
                "$device" "$weight"
        done
        swift-ring-builder "/etc/swift/rings/$name.builder" rebalance
    else
        echo "$name ring is already present"
    fi
}

(
    flock -x -w 60 200

    if [ $? -ne 0 ]; then
        echo "Coundn't acquire lock (waited 60 seconds) "
    fi

    setup_ring account SWIFT_ACCOUNT_BLOCK_DEVICES[@]
    setup_ring container SWIFT_CONTAINER_BLOCK_DEVICES[@]
    setup_ring object SWIFT_OBJECT_BLOCK_DEVICES[@]

) 200>/etc/swift/rings/swift-conf.lock

# Start the service
swift-init -v -n proxy-server start
