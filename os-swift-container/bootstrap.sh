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
SWIFT_HASH_PATH_PREFIX="${SWIFT_HASH_PATH_PREFIX:-default}"
SWIFT_HASH_PATH_SUFFIX="${SWIFT_HASH_PATH_SUFFIX:-default}"

SWIFT_CONFIG_FILE="/etc/swift/swift.conf"

# Configure the service with environment variables defined
sed -i "s#%SWIFT_HASH_PATH_PREFIX%#${SWIFT_HASH_PATH_PREFIX}#" \
    "$SWIFT_CONFIG_FILE"
sed -i "s#%SWIFT_HASH_PATH_SUFFIX%#${SWIFT_HASH_PATH_SUFFIX}#" \
    "$SWIFT_CONFIG_FILE"

# Create recon dir
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift

# Set data dir permissions
chown -R swift:swift /srv/node

DIR_COUNT="$(find /srv/node -type d | wc -l)"
if [ "$DIR_COUNT" -lt 1 ]; then
    echo "!!! No data directory mounted !!!"
    echo "Please add at least 1 volume in /srv/node"
    echo "e.g. docker run -v /srv/node/dev1:srv/node/dev1 ..."
fi

# Start the service
swift-init -v -n object-server start
