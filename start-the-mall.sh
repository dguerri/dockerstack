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
MEMCACHED_HOSTNAME=memcached.os-in-a-box
GLANCE_REGISTRY_HOSTNAME=glance-registry.os-in-a-box
GLANCE_API_HOSTNAME=glance-api.os-in-a-box
NEUTRON_SERVER_HOSTNAME=neutron-server.os-in-a-box
NEUTRON_DHCP_AGENT_HOSTNAME=neutron-dhcp-agent.os-in-a-box
NOVA_CONDUCTOR_HOSTNAME=nova-conductor.os-in-a-box
NOVA_API_HOSTNAME=nova-api.os-in-a-box
NOVA_SCHEDULER_HOSTNAME=nova-scheduler.os-in-a-box
NOVA_COMPUTE_HOSTNAME=nova-compute.os-in-a-box
SWIFT_PROXY_HOSTNAME=swift-proxy.os-in-a-box
SWIFT_ACCOUNT_HOSTNAME=swift-account.os-in-a-box
SWIFT_CONTAINER_HOSTNAME=swift-container.os-in-a-box
SWIFT_OBJECT_HOSTNAME=swift-object.os-in-a-box
IRONIC_API_HOSTNAME=ironic-api.os-in-a-box
IRONIC_CONDUCTOR_HOSTNAME=ironic-conductor.os-in-a-box
IPXE_HTTPD_HOSTNAME=ipxe-httpd.os-in-a-box
PXE_TFTPD_HOSTNAME=pxe-tftp.os-in-a-box

MYSQL_ROOT_PASSWORD=ooGee9Eu2kichaib0oos
KEYSTONE_DB_USER=keystone
KEYSTONE_DB_PASS=uu2xoh8veaS3Ia7Cochu
GLANCE_DB_USER=glance
GLANCE_DB_PASS=etaiPo2paefeitoowieN
NEUTRON_DB_USER=neutron
NEUTRON_DB_PASS=iejo6iec0xahshoep5Sh
NOVA_DB_USER=nova
NOVA_DB_PASS=shei6veelei4ofah8Aep
IRONIC_DB_USER=ironic
IRONIC_DB_PASS=Baeluthac4iNohfo4eip

RABBITMQ_ERLANG_COOKIE=xoo4aighaew1daibae0zaej1esietho7oophiehuem8Gaenee4
GLANCE_RABBITMQ_USER=glance
GLANCE_RABBITMQ_PASS=Shohmaiy9Wai5Vahtuid
NEUTRON_RABBITMQ_USER=neutron
NEUTRON_RABBITMQ_PASS=oohai7geiRooChie5oQu
NOVA_RABBITMQ_USER=nova
NOVA_RABBITMQ_PASS=gai4jaiwohShoo0quaf0
IRONIC_RABBITMQ_USER=ironic
IRONIC_RABBITMQ_PASS=aeG1hu1Ik2ja0vua5aeg

IDENTITY_URI="http://$KEYSTONE_HOSTNAME:35357"
AUTH_URI="http://$KEYSTONE_HOSTNAME:5000/v2.0"
MEMCACHED_SERVERS="$MEMCACHED_HOSTNAME:11211"
GLANCE_SWIFT_CONTAINER="glance"
IRONIC_SWIFT_TEMPURL_KEY="TohNahNgab9ohSha4cheBail7za8Ohlei4ohb2oh"
SWIFT_DEVS_DATA_CONTAINER_NAME=swift-devs-data
SWIFT_RINGS_DATA_CONTAINER_NAME=swift-rings-data
TFTPBOOT_DATA_CONTAINER_NAME=tftpboot-data
HTTPBOOT_DATA_CONTAINER_NAME=httpboot-data

SERVICE_TENANT_NAME=service
KEYSTONE_SERVICE_TOKEN=asohzee4cei2ahd6aig6caew6uapheewaezoGei7
KEYSTONE_ADMIN_PASSWORD=Ve0eequaekeiyaebohlo
GLANCE_SERVICE_USER=glance
GLANCE_SERVICE_PASS=Wiem3ieceigiex6voo8a
NEUTRON_SERVICE_USER=neutron
NEUTRON_SERVICE_PASS=ou0eeNgoo6Paireiphoo
NOVA_SERVICE_USER=nova
NOVA_SERVICE_PASS=as0aMi4thaishaegae1e
SWIFT_SERVICE_USER=swift
SWIFT_SERVICE_PASS=aeya8la0eey5peih1Sa9
IRONIC_SERVICE_USER=ironic
IRONIC_SERVICE_PASS=euch1meeCooNgeaYiSah
IRONIC_SWIFT_TEMP_URL_KEY=ahtui7veer7OoChaesoh0aich9coh3Iu5kaishoh


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
        sleep 1 ; count="$((count - 1))"
    done

    return 1
}

get_container_ip() {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$1"
}

# Create images
make

# Start containers
# ----[ AutoDNS
docker run -d \
    --restart=always \
    --publish 0.0.0.0:53:53/udp \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --name "$AUTODNS_HOSTNAME" \
    --hostname "$AUTODNS_HOSTNAME" \
    rehabstudio/autodns

# ----[ MySQL
docker run -d \
    --restart=always \
    --env MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    --expose 3306 \
    --name "$MYSQL_HOSTNAME" \
    --hostname "$MYSQL_HOSTNAME" \
    os-mysql

wait_host "$MYSQL_HOSTNAME" 3306

# ----[ Memcached
docker run -d \
    --restart=always \
    --expose 11211 \
    --name "$MEMCACHED_HOSTNAME" \
    --hostname "$MEMCACHED_HOSTNAME" \
    os-memcached

wait_host "$MEMCACHED_HOSTNAME" 11211

# Create OpenStack databases
sed "s#%KEYSTONE_DB_USER%#${KEYSTONE_DB_USER:-keystone}#g;\
     s#%KEYSTONE_DB_PASS%#${KEYSTONE_DB_PASS}#g" \
        "$SCRIPT_DIR/sql_scripts/keystone.sql" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

sed "s#%GLANCE_DB_USER%#${GLANCE_DB_USER:-glance}#g;
     s#%GLANCE_DB_PASS%#${GLANCE_DB_PASS}#g" \
        "$SCRIPT_DIR/sql_scripts/glance.sql" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

sed "s#%NEUTRON_DB_USER%#${NEUTRON_DB_USER:-neutron}#g;\
     s#%NEUTRON_DB_PASS%#${NEUTRON_DB_PASS}#g" \
        "$SCRIPT_DIR/sql_scripts/neutron.sql" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

sed "s#%NOVA_DB_USER%#${NOVA_DB_USER:-nova}#g;\
     s#%NOVA_DB_PASS%#${NOVA_DB_PASS}#g" \
        "$SCRIPT_DIR/sql_scripts/nova.sql" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

sed "s#%IRONIC_DB_USER%#${IRONIC_DB_USER:-ironic}#g;\
     s#%IRONIC_DB_PASS%#${IRONIC_DB_PASS}#g" \
        "$SCRIPT_DIR/sql_scripts/ironic.sql" | \
    docker exec -i "$MYSQL_HOSTNAME" \
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -h "localhost"

# ----[ Keystone
docker run -d \
    --restart=always \
    --publish 0.0.0.0:5000:5000/tcp \
    --publish 0.0.0.0:35357:35357/tcp \
    --env KEYSTONE_SERVICE_TOKEN="$KEYSTONE_SERVICE_TOKEN" \
    --env KEYSTONE_DB_HOST="$MYSQL_HOSTNAME" \
    --env KEYSTONE_DB_USER="$KEYSTONE_DB_USER" \
    --env KEYSTONE_DB_PASS="$KEYSTONE_DB_PASS" \
    --env KEYSTONE_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
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
                --publicurl "http://${KEYSTONE_HOSTNAME}:5000/v2.0" \
                --internalurl "http://${KEYSTONE_HOSTNAME}:5000/v2.0" \
                --adminurl "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
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
            --publicurl "http://${GLANCE_API_HOSTNAME}:9292/" \
            --internalurl "http://${GLANCE_API_HOSTNAME}:9292/" \
            --adminurl "http://${GLANCE_API_HOSTNAME}:9292/" \
            --region regionOne

# Swift
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name "$SWIFT_SERVICE_USER" \
                --pass "$SWIFT_SERVICE_PASS" \
                --tenant "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant "$SERVICE_TENANT_NAME" \
                --user "$SWIFT_SERVICE_USER" --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name swift --type object-store

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
            --service swift \
            --publicurl \
                "http://${SWIFT_PROXY_HOSTNAME}:8080/v1/AUTH_%(tenant_id)s" \
            --internalurl \
                "http://${SWIFT_PROXY_HOSTNAME}:8080/v1/AUTH_%(tenant_id)s" \
            --adminurl "http://${SWIFT_PROXY_HOSTNAME}:8080/" \
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

# Ironic API
docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-create --name "$IRONIC_SERVICE_USER" \
                --pass "$IRONIC_SERVICE_PASS" \
                --tenant "$SERVICE_TENANT_NAME"

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            user-role-add --tenant "$SERVICE_TENANT_NAME" \
                --user "$IRONIC_SERVICE_USER" --role admin

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            service-create --name ironic --type baremetal

docker exec -i "$KEYSTONE_HOSTNAME" \
    keystone --os-token "$KEYSTONE_SERVICE_TOKEN" \
        --os-endpoint "http://${KEYSTONE_HOSTNAME}:35357/v2.0" \
            endpoint-create \
            --service ironic \
            --publicurl \
                http://$IRONIC_API_HOSTNAME:6385/ \
            --internalurl \
                http://$IRONIC_API_HOSTNAME:6385/ \
            --adminurl \
                http://$IRONIC_API_HOSTNAME:6385/ \
            --region regionOne

# ----[ RabbitMQ
docker run -d \
    --restart=always \
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
    rabbitmqctl add_user "$IRONIC_RABBITMQ_USER" "$IRONIC_RABBITMQ_PASS"

docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$GLANCE_RABBITMQ_USER" ".*" ".*" ".*"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$NEUTRON_RABBITMQ_USER" ".*" ".*" ".*"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$NOVA_RABBITMQ_USER" ".*" ".*" ".*"
docker exec -i "$RABBITMQ_HOSTNAME" \
    rabbitmqctl set_permissions "$IRONIC_RABBITMQ_USER" ".*" ".*" ".*"

# ----[ Neutron Server
docker run -d \
    --restart=always \
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

# ----[ TFTPboot data container
docker create \
    --volume /tftpboot \
    --name "$TFTPBOOT_DATA_CONTAINER_NAME" \
    os-base-image /bin/true

# ----[ TFTPd server(PXE)
docker run -d \
    --restart=always \
    --publish 0.0.0.0:69:69/udp \
    --name "$PXE_TFTPD_HOSTNAME" \
    --hostname "$PXE_TFTPD_HOSTNAME" \
    --volumes-from "$TFTPBOOT_DATA_CONTAINER_NAME":ro \
    os-tftpboot

wait_host "$PXE_TFTPD_HOSTNAME"
tftpboot_server_ip=$(get_container_ip $PXE_TFTPD_HOSTNAME)

# ----[ HTTPboot data container
docker create \
    --volume /httpboot \
    --name "$HTTPBOOT_DATA_CONTAINER_NAME" \
    os-base-image /bin/true

# ----[ Apache server (iPXE)
docker run -d \
    --restart=always \
    --publish 0.0.0.0:8090:80/tcp \
    --name "$IPXE_HTTPD_HOSTNAME" \
    --hostname "$IPXE_HTTPD_HOSTNAME" \
    --volumes-from "$HTTPBOOT_DATA_CONTAINER_NAME" \
    os-httpboot

wait_host "$IPXE_HTTPD_HOSTNAME" 80
httpboot_server_ip=$(get_container_ip $IPXE_HTTPD_HOSTNAME)

# ----[ Ironic Conductor
docker run -d \
    --restart=always \
    --name "$IRONIC_CONDUCTOR_HOSTNAME" \
    --hostname "$IRONIC_CONDUCTOR_HOSTNAME" \
    --volumes-from "$TFTPBOOT_DATA_CONTAINER_NAME" \
    --volumes-from "$HTTPBOOT_DATA_CONTAINER_NAME" \
    --env IRONIC_DB_HOST="$MYSQL_HOSTNAME" \
    --env IRONIC_DB_USER="$IRONIC_DB_USER" \
    --env IRONIC_DB_PASS="$IRONIC_DB_PASS" \
    --env IRONIC_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env IRONIC_RABBITMQ_USER="$IRONIC_RABBITMQ_USER" \
    --env IRONIC_RABBITMQ_PASS="$IRONIC_RABBITMQ_PASS" \
    --env IRONIC_IDENTITY_URI="$IDENTITY_URI" \
    --env IRONIC_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env IRONIC_SERVICE_USER="$IRONIC_SERVICE_USER" \
    --env IRONIC_SERVICE_PASS="$IRONIC_SERVICE_PASS" \
    --env IRONIC_SWIFT_TEMP_URL_KEY="$IRONIC_SWIFT_TEMP_URL_KEY" \
    --env IRONIC_SWIFT_ENDPOINT_URL="http://$SWIFT_PROXY_HOSTNAME:8080" \
    --env IRONIC_SWIFT_ACCOUNT="$SERVICE_TENANT_NAME:$IRONIC_SERVICE_USER" \
    --env IRONIC_SWIFT_CONTAINER="glance" \
    --env IRONIC_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
    --env IRONIC_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
    --env IRONIC_CLEAN_NODE="false" \
    --env IRONIC_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    --env IRONIC_TFTP_SERVER="$tftpboot_server_ip" \
    --env IRONIC_IPXE_HTTP_URL="http://$httpboot_server_ip:8090" \
    --env IRONIC_USE_IPXE="true" \
    os-ironic-conductor

# ----[ Ironic API
docker run -d \
    --restart=always \
    --name "$IRONIC_API_HOSTNAME" \
    --hostname "$IRONIC_API_HOSTNAME" \
    --publish 0.0.0.0:6385:6385/tcp \
    --env IRONIC_DB_HOST="$MYSQL_HOSTNAME" \
    --env IRONIC_DB_USER="$IRONIC_DB_USER" \
    --env IRONIC_DB_PASS="$IRONIC_DB_PASS" \
    --env IRONIC_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env IRONIC_RABBITMQ_USER="$IRONIC_RABBITMQ_USER" \
    --env IRONIC_RABBITMQ_PASS="$IRONIC_RABBITMQ_PASS" \
    --env IRONIC_IDENTITY_URI="$IDENTITY_URI" \
    --env IRONIC_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env IRONIC_SERVICE_USER="$IRONIC_SERVICE_USER" \
    --env IRONIC_SERVICE_PASS="$IRONIC_SERVICE_PASS" \
    --env IRONIC_SWIFT_TEMP_URL_KEY="$IRONIC_SWIFT_TEMP_URL_KEY" \
    --env IRONIC_SWIFT_ENDPOINT_URL="http://$SWIFT_PROXY_HOSTNAME:8080" \
    --env IRONIC_SWIFT_ACCOUNT="$SERVICE_TENANT_NAME:$IRONIC_SERVICE_USER" \
    --env IRONIC_SWIFT_CONTAINER="glance" \
    --env IRONIC_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
    --env IRONIC_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
    --env IRONIC_CLEAN_NODE=false \
    --env IRONIC_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    os-ironic-api

wait_host "$IRONIC_API_HOSTNAME" 6385

# ----[ Neutron DHCP agent
docker run -d \
    --restart=always \
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
    --restart=always \
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
    --env NOVA_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
    --env NOVA_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
    --env NOVA_IRONIC_API_ENDPOINT="http://$IRONIC_API_HOSTNAME:6385/v1" \
    --env NOVA_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    os-nova-conductor

# ----[ Nova API
docker run -d \
    --restart=always \
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
    --env NOVA_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
    --env NOVA_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
    --env NOVA_IRONIC_API_ENDPOINT="http://$IRONIC_API_HOSTNAME:6385/v1" \
    --env NOVA_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    os-nova-api

wait_host "$NOVA_API_HOSTNAME" 8774

# ----[ Nova Scheduler
docker run -d \
    --restart=always \
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
    --env NOVA_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    --env NOVA_USE_IRONIC="true" \
    os-nova-scheduler

# ----[ Nova Compute
docker run -d \
    --restart=always \
    --privileged=true \
    --volume=/lib/modules:/lib/modules:ro \
    --name "$NOVA_COMPUTE_HOSTNAME" \
    --hostname "$NOVA_COMPUTE_HOSTNAME" \
    --env NOVA_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
    --env NOVA_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
    --env NOVA_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
    --env NOVA_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    --env NOVA_IDENTITY_URI="$IDENTITY_URI" \
    --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
    --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
    --env NOVA_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
    --env NOVA_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
    --env NOVA_IRONIC_API_ENDPOINT="http://$IRONIC_API_HOSTNAME:6385/v1" \
    --env NOVA_USE_IRONIC="true" \
    --env NOVA_IRONIC_SERVICE_USER="$IRONIC_SERVICE_USER" \
    --env NOVA_IRONIC_SERVICE_PASS="$IRONIC_SERVICE_PASS" \
    --env NOVA_IRONIC_AUTH_URI="$AUTH_URI" \
    --env NOVA_IRONIC_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    os-nova-compute

# ---- [ Swift Data Containers
docker create \
    --volume /etc/swift/rings \
    --name "$SWIFT_RINGS_DATA_CONTAINER_NAME" \
    os-base-image /bin/true

docker create \
    --volume /srv/node/dev1 \
    --name "$SWIFT_DEVS_DATA_CONTAINER_NAME" \
    os-base-image /bin/true

# ----[ Swift Account
docker run -d \
    --restart=always \
    --name "$SWIFT_ACCOUNT_HOSTNAME" \
    --hostname "$SWIFT_ACCOUNT_HOSTNAME" \
    --volumes-from "$SWIFT_RINGS_DATA_CONTAINER_NAME" \
    --volumes-from "$SWIFT_DEVS_DATA_CONTAINER_NAME" \
    --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
    --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
    --expose 6002 \
    os-swift-account

wait_host "$SWIFT_ACCOUNT_HOSTNAME" 6002
account_ip=$(get_container_ip $SWIFT_ACCOUNT_HOSTNAME)

# ----[ Swift Container
docker run -d \
    --restart=always \
    --name "$SWIFT_CONTAINER_HOSTNAME" \
    --hostname "$SWIFT_CONTAINER_HOSTNAME" \
    --volumes-from "$SWIFT_RINGS_DATA_CONTAINER_NAME" \
    --volumes-from "$SWIFT_DEVS_DATA_CONTAINER_NAME" \
    --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
    --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
    --expose 6001 \
    os-swift-container

wait_host "$SWIFT_CONTAINER_HOSTNAME" 6001
container_ip=$(get_container_ip $SWIFT_CONTAINER_HOSTNAME)

# ----[ Swift Object
docker run -d \
    --restart=always \
    --name "$SWIFT_OBJECT_HOSTNAME" \
    --hostname "$SWIFT_OBJECT_HOSTNAME" \
    --volumes-from "$SWIFT_RINGS_DATA_CONTAINER_NAME" \
    --volumes-from "$SWIFT_DEVS_DATA_CONTAINER_NAME" \
    --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
    --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
    --expose 6000 \
    os-swift-object

wait_host "$SWIFT_OBJECT_HOSTNAME" 6000
object_ip=$(get_container_ip $SWIFT_OBJECT_HOSTNAME)

# ----[ Swift Proxy
docker run -d \
    --restart=always \
    --name "$SWIFT_PROXY_HOSTNAME" \
    --hostname "$SWIFT_PROXY_HOSTNAME" \
    --volumes-from "$SWIFT_RINGS_DATA_CONTAINER_NAME" \
    --env SWIFT_IDENTITY_URI="$IDENTITY_URI" \
    --env SWIFT_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env SWIFT_SERVICE_USER="$SWIFT_SERVICE_USER" \
    --env SWIFT_SERVICE_PASS="$SWIFT_SERVICE_PASS" \
    --env SWIFT_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
    --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
    --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
    --env SWIFT_REPLICA="3" \
    --env SWIFT_MIN_PART_HOURS="1" \
    --env SWIFT_ACCOUNT_BLOCK_DEVICES="r1z1-$account_ip:6002/dev1" \
    --env SWIFT_CONTAINER_BLOCK_DEVICES="r1z1-$container_ip:6001/dev1" \
    --env SWIFT_OBJECT_BLOCK_DEVICES="r1z1-$object_ip:6000/dev1" \
    os-swift-proxy

wait_host "$SWIFT_PROXY_HOSTNAME" 8080

# ----[ Glance Registry
docker run -d \
    --restart=always \
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
    --restart=always \
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
    --env GLANCE_USE_SWIFT=true \
    --env GLANCE_SWIFT_AUTH_ADDR="$AUTH_URI" \
    --env GLANCE_SWIFT_TENANT_NAME="$SERVICE_TENANT_NAME" \
    --env GLANCE_SWIFT_USER="$GLANCE_SERVICE_USER" \
    --env GLANCE_SWIFT_PASS="$GLANCE_SERVICE_PASS" \
    --env GLANCE_SWIFT_CONTAINER="$GLANCE_SWIFT_CONTAINER" \
    --name "$GLANCE_API_HOSTNAME" \
    --hostname "$GLANCE_API_HOSTNAME" \
    os-glance-api

wait_host "$GLANCE_API_HOSTNAME" 9292
