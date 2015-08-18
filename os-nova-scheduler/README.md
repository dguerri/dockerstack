# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `NOVA_DB_HOST` | | | N
 `NOVA_DB_USER` | | | N
 `NOVA_DB_PASS` | | | Y
 `NOVA_RABBITMQ_HOST` | | | N
 `NOVA_RABBITMQ_USER` | | | N
 `NOVA_RABBITMQ_PASS` | | | Y
 `NOVA_IDENTITY_URI` | | | N
 `NOVA_SERVICE_TENANT_NAME` | | | N
 `NOVA_SERVICE_USER` | | | N
 `NOVA_SERVICE_PASS` | | | Y
 `NOVA_MEMCACHED_SERVERS` | Memcached servers list (comma separated list of address:port couple) | Empty | N

## Examples

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
        --env NOVA_MEMCACHED_SERVERS="$NOVA_MEMCACHED_SERVERS" \
        os-nova-scheduler