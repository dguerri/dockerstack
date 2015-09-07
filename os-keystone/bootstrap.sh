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
KEYSTONE_DB_HOST="${KEYSTONE_DB_HOST:-localhost}"
KEYSTONE_DB_USER="${KEYSTONE_DB_USER:-keystone}"
# KEYSTONE_DB_PASS
# KEYSTONE_SERVICE_TOKEN
KEYSTONE_MEMCACHED_SERVERS="${KEYSTONE_MEMCACHED_SERVERS:-}"

# Enable memcached if needed
if [ -z "$KEYSTONE_MEMCACHED_SERVERS" ]; then
    MEMCACHE_ENABLED=false
    CACHE_BACKEND=keystone.common.cache.noop
else
    MEMCACHE_ENABLED=true
    CACHE_BACKEND=keystone.cache.memcache_pool
fi

DATABASE_CONNECTION=\
"mysql://${KEYSTONE_DB_USER}:${KEYSTONE_DB_PASS}@${KEYSTONE_DB_HOST}/keystone"
CONFIG_FILE="/etc/keystone/keystone.conf"

# Configure the service with environment variables defined
sed -i -e "s#%KEYSTONE_SERVICE_TOKEN%#${KEYSTONE_SERVICE_TOKEN}#" \
    -e "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" \
    -e "s#%KEYSTONE_MEMCACHED_SERVERS%#${KEYSTONE_MEMCACHED_SERVERS}#" \
    -e "s#%MEMCACHE_ENABLED%#${MEMCACHE_ENABLED}#" \
    -e "s#%CACHE_BACKEND%#${CACHE_BACKEND}#" "$CONFIG_FILE"

# Migrate keystone database
sudo -u keystone keystone-manage -v db_sync

# Start the service
keystone-all
