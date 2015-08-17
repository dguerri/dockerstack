# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `SWIFT_IDENTITY_URI` | | `http://127.0.0.1:35357` | N
 `SWIFT_SERVICE_TENANT_NAME` | | `service` | N
 `SWIFT_SERVICE_USER` | | `swift` | N
 `SWIFT_SERVICE_PASS` | | None | Y
 `SWIFT_MEMCACHE_SERVERS` | | Empty | N
 `SWIFT_HASH_PATH_PREFIX` | | `docker` | N
 `SWIFT_HASH_PATH_SUFFIX` | | `docker` | N
 `SWIFT_PART_POWER` | | `10` | N
 `SWIFT_REPLICA` | | `3` specified| N
 `SWIFT_MIN_PART_HOURS` | | `1` | N
 `SWIFT_ACCOUNT_BLOCK_DEVICES` | Comma separated list of account storage devices: r<region#>-z<zone#>-<ip>:<port>/<device>;[weight]. [weight] defaults to 100. | | Y
 `SWIFT_CONTAINER_BLOCK_DEVICES` | Comma separated list of container storage devices: r<region#>-z<zone#>-<ip>:<port>/<device>;[weight]. [weight] defaults to 100. | | Y
 `SWIFT_OBJECT_BLOCK_DEVICES` | Comma separated list of object storage devices: r<region#>-z<zone#>-<ip>:<port>/<device>;[weight]. [weight] defaults to 100. | | Y

## Examples

    docker run -d \
        --restart=on-failure:10 \
        --name "$SWIFT_PROXY_HOSTNAME" \
        --hostname "$SWIFT_PROXY_HOSTNAME" \
        --volume /etc/swift/rings \
        --env SWIFT_IDENTITY_URI="$IDENTITY_URI" \
        --env SWIFT_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
        --env SWIFT_SERVICE_USER="$SWIFT_SERVICE_USER" \
        --env SWIFT_SERVICE_PASS="$SWIFT_SERVICE_PASS" \
        --env SWIFT_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
        --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
        --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
        --env SWIFT_REPLICA="2" \
        --env SWIFT_MIN_PART_HOURS="1" \
        --env SWIFT_ACCOUNT_BLOCK_DEVICES="r1z1-$IP_NODE1:6002/sdb1" \
        --env SWIFT_CONTAINER_BLOCK_DEVICES="r1z1-$IP_NODE1:6001/sdb1" \
        --env SWIFT_OBJECT_BLOCK_DEVICES="r1z1-$IP_NODE1:6000/sdb1" \
        os-swift-proxy
