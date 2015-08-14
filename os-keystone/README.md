# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `KEYSTONE_SERVICE_TOKEN` | OpenStack service token used to bootstrap a new OpenStack instance | None | Y
 `KEYSTONE_DB_HOST` | Mysql database hostname or ip address | `localhost` | N
 `KEYSTONE_DB_PASS` | `keystone` database password | None                             | Y
 `KEYSTONE_DB_USER` | `keystone` database user | `keystone`                       | N
 `MYSQL_ROOT_PASSWORD` | Mysql `root` password, used to create Keystone database | `$MYSQL_ENV_MYSQL_ROOT_PASSWORD` | Y


## Examples

Using all the environment variables

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
