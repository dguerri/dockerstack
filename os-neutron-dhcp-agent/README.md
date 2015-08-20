# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `NEUTRON_IDENTITY_URI` | | `http://127.0.0.1:35357` | N
 `NEUTRON_SERVICE_TENANT_NAME` | | `service` | N
 `NEUTRON_SERVICE_USER` | | `neutron` | N
 `NEUTRON_SERVICE_PASS` | | None | Y
 `NEUTRON_RABBITMQ_HOST` | | `localhost` | N
 `NEUTRON_RABBITMQ_USER` | | `guest` | N
 `NEUTRON_RABBITMQ_PASS` | | `guest` | N
 `NEUTRON_EXTERNAL_NETWORKS` | | `external` | N
 `NEUTRON_BRIDGE_MAPPINGS` | | `external:br-ex` | N
 `NEUTRON_ENABLE_IPXE` | | `false` | N

## Examples

    docker run -d \
        --restart=on-failure:10 \
        --privileged=true \
         --volume=/lib/modules:/lib/modules:ro \
        --env NEUTRON_IDENTITY_URI="$IDENTITY_URI" \
        --env NEUTRON_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
        --env NEUTRON_SERVICE_USER="$NEUTRON_SERVICE_USER" \
        --env NEUTRON_SERVICE_PASS="$NEUTRON_SERVICE_PASS" \
        --env NEUTRON_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
        --env NEUTRON_RABBITMQ_USER="$NEUTRON_RABBITMQ_USER" \
        --env NEUTRON_RABBITMQ_PASS="$NEUTRON_RABBITMQ_PASS" \
        --env NEUTRON_ENABLE_IPXE="true" \
        --name "$NEUTRON_DHCP_AGENT_HOSTNAME" \
        --hostname "$NEUTRON_DHCP_AGENT_HOSTNAME" \
        os-neutron-dhcp-agent
