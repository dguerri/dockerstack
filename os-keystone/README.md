# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `KEYSTONE_ADMIN_TOKEN` | OpenStack admin token used to bootstrap a new OpenStack instance | None | Y
 `KEYSTONE_DB_HOST` | Mysql database hostname or ip address | `localhost` | N
 `KEYSTONE_DB_PASS` | `keystone` database password | None                             | Y
 `KEYSTONE_DB_USER` | `keystone` database user | `keystone`                       | N
 `MYSQL_ROOT_PASSWORD` | Mysql `root` password, used to create Keystone database | `$MYSQL_ENV_MYSQL_ROOT_PASSWORD` | Y


## Examples

Using all the environment variables

    docker run -d \
      -e KEYSTONE_ADMIN_TOKEN=admintoken \
      -e KEYSTONE_DB_HOST=keystonedbhost \
      -e KEYSTONE_DB_PASS=keystonedbpass \
      -e KEYSTONE_DB_USER=keystonedbuser \
      -e MYSQL_ROOT_PASSWORD=mysqlrootpassword \
      --name keystone \
      -h keystone os-keystone


In the following example `MYSQL_ROOT_PASSWORD` will be set to `$MYSQL_ENV_MYSQL_ROOT_PASSWORD`.
Moreover we use the default value for `KEYSTONE_DB_USER` (`keystone`)

    docker run -d \
      -e KEYSTONE_ADMIN_TOKEN=admintoken \
      -e KEYSTONE_DB_PASS=keystonedbpass \
      --link mysql:mysql \
      --name keystone \
      -h keystone os-keystone
