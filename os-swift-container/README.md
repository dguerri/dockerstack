# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `SWIFT_HASH_PATH_PREFIX` | | `docker` | N
 `SWIFT_HASH_PATH_SUFFIX` | | `docker` | N

## Examples

    docker run -d \
        --restart=on-failure:10 \
        --name "$SWIFT_PROXY_HOSTNAME" \
        --hostname "$SWIFT_PROXY_HOSTNAME" \
        --volume /etc/swift/rings:/etc/swift/rings \
        --volume /srv/node/dev1:srv/node/dev1 \
        --env SWIFT_HASH_PATH_PREFIX="os-in-a-box" \
        --env SWIFT_HASH_PATH_SUFFIX="os-in-a-box" \
        os-swift-container
