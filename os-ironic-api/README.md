# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `IRONIC_DB_HOST` | | `localhost` | N
 `IRONIC_DB_USER` | | `ironic` | N
 `IRONIC_DB_PASS` | | None | Y
 `IRONIC_CLEAN_NODE` | | `false` | N
 `IRONIC_SWIFT_TEMP_URL_KEY` | | None | Y
 `IRONIC_SWIFT_ENDPOINT_URL` | | None | Y
 `IRONIC_SWIFT_ACCOUNT` | | None | Y
 `IRONIC_SWIFT_CONTAINER` | | `glance` | N
 `IRONIC_GLANCE_API_URLS` | Comma separated list of Glance servers | `http://127.0.0.1:9292` | N
 `IRONIC_IDENTITY_URI` | | `http://127.0.0.1:35357` | N
 `IRONIC_SERVICE_TENANT_NAME` | | `service` | N
 `IRONIC_SERVICE_USER` | | `ironic` | N
 `IRONIC_SERVICE_PASS` | | None | Y
 `IRONIC_NEUTRON_SERVER_URL` | | `http://127.0.0.1:9696` | N
 `IRONIC_RABBITMQ_HOST` | | `127.0.0.1` | N
 `IRONIC_RABBITMQ_USER` | | `ironic` | N
 `IRONIC_RABBITMQ_PASS` | | None | Y
 `IRONIC_MEMCACHED_SERVERS` | Memcached servers list (comma separated list of address:port couple) | Empty | N
 `IRONIC_NOTIFICATIONS` | Enable notifications | `false` | N


## Examples

    docker run -d \
        --restart=on-failure:10 \
        --name "$IRONIC_API_HOSTNAME" \
        --hostname "$IRONIC_API_HOSTNAME" \
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
        --env IRONIC_CLEAN_NODE=true \
        --env IRONIC_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
        --env IRONIC_NOTIFICATIONS="true" \
        os-ironic-api
