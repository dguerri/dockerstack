#!/bin/bash

set -x
set -e
set -u
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MYSQL_ROOT_PASSWORD=ooGee9Eu2kichaib0oos
KEYSTONE_SERVICE_TOKEN=asohzee4cei2ahd6aig6caew6uapheewaezoGei7
KEYSTONE_ADMIN_PASSWORD=Ve0eequaekeiyaebohlo
KEYSTONE_DB_PASS=uu2xoh8veaS3Ia7Cochu
MYSQL_HOSTNAME=mysql.os-in-a-box
KEYSTONE_HOSTNAME=keystone.os-in-a-box
AUTODNS_HOSTNAME=autodns.os-in-a-box
RABBITMQ_HOSTNAME=rabbitmq.os-in-a-box
RABBITMQ_ERLANG_COOKIE=xoo4aighaew1daibae0zaej1esietho7oophiehuem8Gaenee4
GLANCE_REGISTRY_HOSTNAME=glance-registry.os-in-a-box
GLANCE_DB_PASS=etaiPo2paefeitoowieN
GLANCE_RABBITMQ_USER=glance
GLANCE_RABBITMQ_PASS=Shohmaiy9Wai5Vahtuid
IDENTITY_URI="http://$KEYSTONE_HOSTNAME:35357"
SERVICE_TENANT_NAME=service
GLANCE_SERVICE_USER=glance
GLANCE_SERVICE_PASS=Wiem3ieceigiex6voo8a
GLANCE_API_HOSTNAME=glance-api.os-in-a-box

wait_host() {
    local hostname="$1"
    local port="${2:-}"
    local count=10
    local ret

    while [ "$count" -ge 0 ]; do
        set +e
        if [ -z "$port" ]; then
            docker exec -i "$AUTODNS_HOSTNAME" ping -w1 -c2  "$hostname"
        else
            docker exec -i "$AUTODNS_HOSTNAME" nc -w1 -z "$hostname" "$port"
        fi
        ret=$?
        set -e
        [ $ret -eq 0 ] && return 0
        sleep 1 ; count="$((count-1))"
    done

    return 1
}

make -j5

# ----[ AutoDNS
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:53:53/udp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --name "$AUTODNS_HOSTNAME" \
    --hostname "$AUTODNS_HOSTNAME" \
    rehabstudio/autodns

# ----[ MySQL
docker run -d \
    --restart=on-failure:10 \
    --env MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    --expose 3306 \
    --name "$MYSQL_HOSTNAME" \
    --hostname "$MYSQL_HOSTNAME" \
    os-mysql

wait_host "$MYSQL_HOSTNAME" 3306

# Create OpenStack databases
cat "$SCRIPT_DIR"/sql_scripts/*.sql | \
    sed "s#%KEYSTONE_DB_USER%#${KEYSTONE_DB_USER:-keystone}#" | \
    sed "s#%KEYSTONE_DB_PASS%#${KEYSTONE_DB_PASS}#" | \
    sed "s#%GLANCE_DB_USER%#${GLANCE_DB_USER:-glance}#" | \
    sed "s#%GLANCE_DB_PASS%#${GLANCE_DB_PASS}#" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

# ----[ Keystone
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:5000:5000/tcp \
    --publish 0.0.0.0:35357:35357/tcp \
    --env KEYSTONE_SERVICE_TOKEN="$KEYSTONE_SERVICE_TOKEN" \
    --env KEYSTONE_DB_HOST="$MYSQL_HOSTNAME" \
    --env KEYSTONE_DB_PASS="$KEYSTONE_DB_PASS" \
    --name "$KEYSTONE_HOSTNAME" \
    --hostname "$KEYSTONE_HOSTNAME" \
    os-keystone


wait_host "$KEYSTONE_HOSTNAME" 35357
wait_host "$KEYSTONE_HOSTNAME" 5000

# Create OpenStack users/tenants/roles/services/endpoints

# Keystone
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            tenant-create --name admin
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            tenant-create --name "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            role-create --name admin
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            role-create --name _member_

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name admin \
                --pass "$KEYSTONE_ADMIN_PASSWORD" \
                --tenant admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant admin --user admin --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name keystone --type identity
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
                --service keystone \
                --publicurl http://${KEYSTONE_HOSTNAME}:5000/v2.0 \
                --internalurl http://${KEYSTONE_HOSTNAME}:5000/v2.0 \
                --adminurl http://${KEYSTONE_HOSTNAME}:35357/v2.0 \
                --region regionOne

# Glance API
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name "$GLANCE_SERVICE_USER" \
                --pass "$GLANCE_SERVICE_PASS" \
                --tenant "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant "$SERVICE_TENANT_NAME" \
                --user "$GLANCE_SERVICE_USER" --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name glance --type image

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
            --service glance \
            --publicurl http://${GLANCE_API_HOSTNAME}:9292/ \
            --internalurl http://${GLANCE_API_HOSTNAME}:9292/ \
            --adminurl http://${GLANCE_API_HOSTNAME}:9292/ \
            --region regionOne

# ----[ RabbitMQ
docker run -d \
    --restart=on-failure:10 \
    --env RABBITMQ_ERLANG_COOKIE="$RABBITMQ_ERLANG_COOKIE" \
    --expose 5672 \
    --name "$RABBITMQ_HOSTNAME" \
    --hostname "$RABBITMQ_HOSTNAME" \
    os-rabbitmq

wait_host "$RABBITMQ_HOSTNAME" 5672

# Create OpenStack RabitMQ users
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl add_user "$GLANCE_RABBITMQ_USER" "$GLANCE_RABBITMQ_PASS"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$GLANCE_RABBITMQ_USER" ".*" ".*" ".*"

# ----[ Glance Registry
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:9191:9191/tcp \
    --env GLANCE_DB_HOST="$MYSQL_HOSTNAME" \
    --env GLANCE_DB_PASS="$GLANCE_DB_PASS" \
    --env GLANCE_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env GLANCE_RABBITMQ_USER="$GLANCE_RABBITMQ_USER" \
    --env GLANCE_RABBITMQ_PASS="$GLANCE_RABBITMQ_PASS" \
    --env GLANCE_IDENTITY_URI="$IDENTITY_URI" \
    --env GLANCE_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env GLANCE_SERVICE_USER="$GLANCE_SERVICE_USER" \
    --env GLANCE_SERVICE_PASS="$GLANCE_SERVICE_PASS" \
    --name "$GLANCE_REGISTRY_HOSTNAME" \
    --hostname "$GLANCE_REGISTRY_HOSTNAME" \
    os-glance-registry

wait_host "$GLANCE_REGISTRY_HOSTNAME" 9191

# ----[ Glance API
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:9292:9292/tcp \
    --env GLANCE_DB_HOST="$MYSQL_HOSTNAME" \
    --env GLANCE_DB_PASS="$GLANCE_DB_PASS" \
    --env GLANCE_REGISTRY_HOST="$GLANCE_REGISTRY_HOSTNAME" \
    --env GLANCE_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env GLANCE_RABBITMQ_USER="$GLANCE_RABBITMQ_USER" \
    --env GLANCE_RABBITMQ_PASS="$GLANCE_RABBITMQ_PASS" \
    --env GLANCE_IDENTITY_URI="$IDENTITY_URI" \
    --env GLANCE_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env GLANCE_SERVICE_USER="$GLANCE_SERVICE_USER" \
    --env GLANCE_SERVICE_PASS="$GLANCE_SERVICE_PASS" \
    --name "$GLANCE_API_HOSTNAME" \
    --hostname "$GLANCE_API_HOSTNAME" \
    os-glance-api

wait_host "$GLANCE_API_HOSTNAME" 9292
