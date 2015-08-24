# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `NEUTRON_DB_HOST` | | `localhost` | N
 `NEUTRON_DB_USER` | | `neutron` | N
 `NEUTRON_DB_PASS` | | None | Y
 `NEUTRON_NOVA_URL` | | `http://127.0.0.1:8774/v2` | N
 `NEUTRON_IDENTITY_URI` | | `http://127.0.0.1:35357` | N
 `NEUTRON_SERVICE_TENANT_NAME` | | `service` | N
 `NEUTRON_SERVICE_USER` | | `neutron` | N
 `NEUTRON_SERVICE_PASS` | | None | Y
 `NOVA_AUTH_URL` | | `http://127.0.0.1:35357` | N
 `NOVA_SERVICE_TENANT_NAME` | | `service` | N
 `NOVA_SERVICE_USER` | | `service` | N
 `NOVA_SERVICE_PASS` | | None | Y
 `NEUTRON_RABBITMQ_HOST` | | `localhost` | N
 `NEUTRON_RABBITMQ_USER` | | `guest` | N
 `NEUTRON_RABBITMQ_PASS` | | `guest` | N
 `NEUTRON_EXTERNAL_NETWORKS` | | `external` | N
 `NEUTRON_BRIDGE_MAPPINGS` | | `external:br-ex` | N


## Examples

    docker run -d \
        --restart=on-failure:10 \
        --publish 0.0.0.0:9696:9696/tcp \
        --env NEUTRON_DB_HOST="$MYSQL_HOSTNAME" \
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
