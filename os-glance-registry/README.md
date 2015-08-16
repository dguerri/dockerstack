# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `GLANCE_DB_HOST` | Database server | `localhost` | N
 `GLANCE_DB_USER` | `glance` database user | `keystone` | N
 `GLANCE_DB_PASS` | `glance` database password | None | Y
 `GLANCE_RABBITMQ_HOST` | RabbitMQ host | `localhost` | N
 `GLANCE_RABBITMQ_USER` | RabbitMQ user | `guest` | N
 `GLANCE_RABBITMQ_PASS` | RabbitMQ password | `guest` | N
 `GLANCE_IDENTITY_URI` | Keystone endpoint. e.g. `http://keystone:35357`| None | Y
 `GLANCE_SERVICE_TENANT_NAME` | Glance service tenant name | `service` | N
 `GLANCE_SERVICE_USER` | Glance service tenant user | `glance` | N
 `GLANCE_SERVICE_PASS` | Glance service tenant password | None | Y

## Examples

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
