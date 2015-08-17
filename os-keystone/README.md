# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `KEYSTONE_SERVICE_TOKEN` | OpenStack service token used to bootstrap a new OpenStack instance | None | Y
 `KEYSTONE_DB_HOST` | Mysql database hostname or ip address | `localhost` | N
 `KEYSTONE_DB_PASS` | `keystone` database password | None                             | Y
 `KEYSTONE_DB_USER` | `keystone` database user | `keystone`                       | N
 `KEYSTONE_MEMCACHED_SERVERS` | Memcached servers list (comma separated list of address:port couple) | Empty | N

## Examples

    docker run -d \
        --restart=on-failure:10 \
        --publish 0.0.0.0:5000:5000/tcp \
        --publish 0.0.0.0:35357:35357/tcp \
        --env KEYSTONE_SERVICE_TOKEN="$KEYSTONE_SERVICE_TOKEN" \
        --env KEYSTONE_DB_HOST="$MYSQL_HOSTNAME" \
        --env KEYSTONE_DB_PASS="$KEYSTONE_DB_PASS" \
        --env KEYSTONE_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
        --name "$KEYSTONE_HOSTNAME" \
        --hostname "$KEYSTONE_HOSTNAME" \
        os-keystone
