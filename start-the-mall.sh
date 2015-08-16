#!/bin/bash

set -x
set -e
set -u
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

AUTODNS_HOSTNAME=autodns.os-in-a-box
MYSQL_HOSTNAME=mysql.os-in-a-box
KEYSTONE_HOSTNAME=keystone.os-in-a-box
RABBITMQ_HOSTNAME=rabbitmq.os-in-a-box
GLANCE_REGISTRY_HOSTNAME=glance-registry.os-in-a-box
GLANCE_API_HOSTNAME=glance-api.os-in-a-box
NEUTRON_SERVER_HOSTNAME=neutron-server.os-in-a-box
NEUTRON_DHCP_AGENT_HOSTNAME=neutron-dhcp-agent.os-in-a-box
NOVA_CONDUCTOR_HOSTNAME=nova-conductor.os-in-a-box
NOVA_API_HOSTNAME=nova-api.os-in-a-box
NOVA_SCHEDULER_HOSTNAME=nova-scheduler.os-in-a-box

MYSQL_ROOT_PASSWORD=ooGee9Eu2kichaib0oos
KEYSTONE_DB_USER=keystone
KEYSTONE_DB_PASS=uu2xoh8veaS3Ia7Cochu
GLANCE_DB_USER=glance
GLANCE_DB_PASS=etaiPo2paefeitoowieN
NEUTRON_DB_USER=neutron
NEUTRON_DB_PASS=iejo6iec0xahshoep5Sh
NOVA_DB_USER=nova
NOVA_DB_PASS=shei6veelei4ofah8Aep

RABBITMQ_ERLANG_COOKIE=xoo4aighaew1daibae0zaej1esietho7oophiehuem8Gaenee4
GLANCE_RABBITMQ_USER=glance
GLANCE_RABBITMQ_PASS=Shohmaiy9Wai5Vahtuid
NEUTRON_RABBITMQ_USER=neutron
NEUTRON_RABBITMQ_PASS=oohai7geiRooChie5oQu
NOVA_RABBITMQ_USER=nova
NOVA_RABBITMQ_PASS=gai4jaiwohShoo0quaf0

IDENTITY_URI="http://$KEYSTONE_HOSTNAME:35357"
SERVICE_TENANT_NAME=service
KEYSTONE_SERVICE_TOKEN=asohzee4cei2ahd6aig6caew6uapheewaezoGei7
KEYSTONE_ADMIN_PASSWORD=Ve0eequaekeiyaebohlo
GLANCE_SERVICE_USER=glance
GLANCE_SERVICE_PASS=Wiem3ieceigiex6voo8a
NEUTRON_SERVICE_USER=neutron
NEUTRON_SERVICE_PASS=ou0eeNgoo6Paireiphoo
NOVA_SERVICE_USER=nova
NOVA_SERVICE_PASS=as0aMi4thaishaegae1e


wait_host() {
    local hostname="$1"
    local port="${2:-}"
    local count=20
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
cat "$SCRIPT_DIR"/sql_scripts/keystone.sql | \
    sed "s#%KEYSTONE_DB_USER%#${KEYSTONE_DB_USER:-keystone}#" | \
    sed "s#%KEYSTONE_DB_PASS%#${KEYSTONE_DB_PASS}#" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

cat "$SCRIPT_DIR"/sql_scripts/glance.sql | \
    sed "s#%GLANCE_DB_USER%#${GLANCE_DB_USER:-glance}#" | \
    sed "s#%GLANCE_DB_PASS%#${GLANCE_DB_PASS}#" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

cat "$SCRIPT_DIR"/sql_scripts/neutron.sql | \
    sed "s#%NEUTRON_DB_USER%#${NEUTRON_DB_USER:-neutron}#" | \
    sed "s#%NEUTRON_DB_PASS%#${NEUTRON_DB_PASS}#" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

cat "$SCRIPT_DIR"/sql_scripts/nova.sql | \
    sed "s#%NOVA_DB_USER%#${NOVA_DB_USER:-nova}#" | \
    sed "s#%NOVA_DB_PASS%#${NOVA_DB_PASS}#" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

# ----[ Keystone
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:5000:5000/tcp \
    --publish 0.0.0.0:35357:35357/tcp \
    --env KEYSTONE_SERVICE_TOKEN="$KEYSTONE_SERVICE_TOKEN" \
    --env KEYSTONE_DB_HOST="$MYSQL_HOSTNAME" \
    --env KEYSTONE_DB_USER="$KEYSTONE_DB_USER" \
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

# Neutron Server
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name "$NEUTRON_SERVICE_USER" \
                --pass "$NEUTRON_SERVICE_PASS" \
                --tenant "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant "$SERVICE_TENANT_NAME" \
                --user "$NEUTRON_SERVICE_USER" --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name neutron --type network

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
            --service neutron \
            --publicurl http://${NEUTRON_SERVER_HOSTNAME}:9696/ \
            --internalurl http://${NEUTRON_SERVER_HOSTNAME}:9696/ \
            --adminurl http://${NEUTRON_SERVER_HOSTNAME}:9696/ \
            --region regionOne

# Nova API
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name "$NOVA_SERVICE_USER" \
                --pass "$NOVA_SERVICE_PASS" \
                --tenant "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant "$SERVICE_TENANT_NAME" \
                --user "$NOVA_SERVICE_USER" --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name nova --type compute

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
            --service nova \
            --publicurl \
                http://${NOVA_API_HOSTNAME}:8774/v2/%\(tenant_id\)s \
            --internalurl \
                http://${NOVA_API_HOSTNAME}:8774/v2/%\(tenant_id\)s \
            --adminurl \
                http://${NOVA_API_HOSTNAME}:8774/v2/%\(tenant_id\)s \
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
    rabbitmqctl add_user "$NEUTRON_RABBITMQ_USER" "$NEUTRON_RABBITMQ_PASS"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl add_user "$NOVA_RABBITMQ_USER" "$NOVA_RABBITMQ_PASS"

docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$GLANCE_RABBITMQ_USER" ".*" ".*" ".*"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$NEUTRON_RABBITMQ_USER" ".*" ".*" ".*"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$NOVA_RABBITMQ_USER" ".*" ".*" ".*"

# ----[ Glance Registry
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:9191:9191/tcp \
    --env GLANCE_DB_HOST="$MYSQL_HOSTNAME" \
    --env GLANCE_DB_USER="$GLANCE_DB_USER" \
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
    --env GLANCE_DB_USER="$GLANCE_DB_USER" \
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

# ----[ Neutron Server
docker run -d \
    --restart=on-failure:10 \
    --publish 0.0.0.0:9696:9696/tcp \
    --env NEUTRON_DB_HOST="$MYSQL_HOSTNAME" \
    --env NEUTRON_DB_USER="$NEUTRON_DB_USER" \
    --env NEUTRON_DB_PASS="$NEUTRON_DB_PASS" \
    --env NEUTRON_NOVA_URL="http://$NOVA_API_HOSTNAME:8774/v2" \
    --env NEUTRON_IDENTITY_URI="$IDENTITY_URI" \
    --env NEUTRON_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NEUTRON_SERVICE_USER="$NEUTRON_SERVICE_USER" \
    --env NEUTRON_SERVICE_PASS="$NEUTRON_SERVICE_PASS" \
    --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
    --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
    --env NEUTRON_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NEUTRON_RABBITMQ_USER="$NEUTRON_RABBITMQ_USER" \
    --env NEUTRON_RABBITMQ_PASS="$NEUTRON_RABBITMQ_PASS" \
    --name "$NEUTRON_SERVER_HOSTNAME" \
    --hostname "$NEUTRON_SERVER_HOSTNAME" \
    os-neutron-server

wait_host "$NEUTRON_SERVER_HOSTNAME" 9696

# ----[ Neutron DHCP agent
docker run -d \
    --restart=on-failure:10 \
    --privileged=true \
     --volume=/lib/modules:/lib/modules:ro \
    --env NEUTRON_IDENTITY_URI="$IDENTITY_URI" \
    --env NEUTRON_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NEUTRON_SERVICE_USER="$NEUTRON_SERVICE_USER" \
    --env NEUTRON_SERVICE_PASS="$NEUTRON_SERVICE_PASS" \
    --env NEUTRON_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NEUTRON_RABBITMQ_USER="$NEUTRON_RABBITMQ_USER" \
    --env NEUTRON_RABBITMQ_PASS="$NEUTRON_RABBITMQ_PASS" \
    --name "$NEUTRON_DHCP_AGENT_HOSTNAME" \
    --hostname "$NEUTRON_DHCP_AGENT_HOSTNAME" \
    os-neutron-dhcp-agent

# ----[ Nova Conductor
docker run -d \
    --restart=on-failure:10 \
    --name "$NOVA_CONDUCTOR_HOSTNAME" \
    --hostname "$NOVA_CONDUCTOR_HOSTNAME" \
    --env NOVA_DB_HOST="$MYSQL_HOSTNAME" \
    --env NOVA_DB_USER="$NOVA_DB_USER" \
    --env NOVA_DB_PASS="$NOVA_DB_PASS" \
    --env NOVA_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NOVA_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
    --env NOVA_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
    --env NOVA_IDENTITY_URI="$IDENTITY_URI" \
    --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
    --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
    --env NOVA_GLANCE_API_HOST="$GLANCE_API_HOSTNAME" \
    --env NOVA_NEUTRON_SERVER_HOST="$NEUTRON_SERVER_HOSTNAME" \
    os-nova-conductor

# ----[ Nova API
docker run -d \
    --restart=on-failure:10 \
    --privileged=true \
     --volume=/lib/modules:/lib/modules:ro \
    --name "$NOVA_API_HOSTNAME" \
    --hostname "$NOVA_API_HOSTNAME" \
    --env NOVA_DB_HOST="$MYSQL_HOSTNAME" \
    --env NOVA_DB_USER="$NOVA_DB_USER" \
    --env NOVA_DB_PASS="$NOVA_DB_PASS" \
    --env NOVA_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NOVA_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
    --env NOVA_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
    --env NOVA_IDENTITY_URI="$IDENTITY_URI" \
    --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
    --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
    --env NOVA_GLANCE_API_HOST="$GLANCE_API_HOSTNAME" \
    --env NOVA_NEUTRON_SERVER_HOST="$NEUTRON_SERVER_HOSTNAME" \
    os-nova-api

wait_host "$NOVA_API_HOSTNAME" 8774

# ----[ Nova Scheduler
docker run -d \
    --restart=on-failure:10 \
    --name "$NOVA_SCHEDULER_HOSTNAME" \
    --hostname "$NOVA_SCHEDULER_HOSTNAME" \
    --env NOVA_DB_HOST="$MYSQL_HOSTNAME" \
    --env NOVA_DB_USER="$NOVA_DB_USER" \
    --env NOVA_DB_PASS="$NOVA_DB_PASS" \
    --env NOVA_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NOVA_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
    --env NOVA_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
    --env NOVA_IDENTITY_URI="$IDENTITY_URI" \
    --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
    --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
    os-nova-scheduler
