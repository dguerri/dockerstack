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


wait_host() {
    local hostname="$1"
    local count=10
    local ret
    while [ "$count" -ge 0 ]; do
        set +e; ping -c2  "$hostname"; ret=$?; set -e
        [ $ret -eq 0 ] && return 0
        sleep 1; count="$((count-1))"
    done
    return 1
}


# Environment variables default values setup
MYSQL_ROOT_PASSWORD="${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-$MYSQL_ROOT_PASSWORD}"

DATABASE_CONNECTION="<CHANGE ME>"
CONFIG_FILE="<CHANGE ME>"
SQL_SCRIPT="<CHANGE ME>"

# Configure the service with environment variables defined
sed -i "s###" "$CONFIG_FILE"

# Prepare the sql script to initialize the DB (if needed)
sed -i "s###" "$SQL_SCRIPT"

# Wait for <CHANGE ME>
wait_host "<CHANGE ME>"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "<CHANGE ME>" < "$SQL_SCRIPT"

# Start the service
<CHANGE ME>
