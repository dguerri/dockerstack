# How to use this container

## Environment variable used by this container

 Variable | Description | Default value | Required
 --- |---| --- | ----
 `NOVA_RABBITMQ_HOST` | | | N
 `NOVA_RABBITMQ_USER` | | | N
 `NOVA_RABBITMQ_PASS` | | | Y
 `NOVA_MEMCACHED_SERVERS` | Memcached servers list (comma separated list of address:port couple) | Empty | N
 `NOVA_IDENTITY_URI` | | | N
 `NOVA_SERVICE_TENANT_NAME` | | | N
 `NOVA_SERVICE_USER` | | | N
 `NOVA_SERVICE_PASS` | | | Y
 `NOVA_GLANCE_API_URLS` | | | N
 `NOVA_USE_IRONIC` | | | N
 `NOVA_NEUTRON_SERVER_URL` | | | N
 `NOVA_NEUTRON_AUTH_URI` | | | N
 `NOVA_NEUTRON_SERVICE_USER` | | | N
 `NOVA_NEUTRON_SERVICE_PASS` | | | Y
 `NOVA_NEUTRON_SERVICE_TENANT_NAME` | | | N
 `NOVA_USE_IRONIC` | | | N
 `NOVA_IRONIC_SERVICE_USER` | | | N
 `NOVA_IRONIC_SERVICE_PASS` | | | N
 `NOVA_IRONIC_AUTH_URI` | | | N
 `NOVA_IRONIC_SERVICE_TENANT_NAME` | | | N
 `NOVA_NOTIFICATIONS` | Whether to enable notifications in Nova | `false` | N
 `NOVA_NOTIFY_ON_STATE_CHANGE` | Which notifications are sent. Acceptable values: `vm_state`, `vm_and_task_state`, `None` | `vm_state` | N
 `NOVA_VIRT_TYPE` | | `kvm` | N
 `NEUTRON_IDENTITY_URI` | | `http://127.0.0.1:35357` | N
 `NEUTRON_SERVICE_TENANT_NAME` | | `service` | N
 `NEUTRON_SERVICE_USER` | | `neutron` | N
 `NEUTRON_SERVICE_PASS` | | None | Y
 `NEUTRON_RABBITMQ_HOST` | | `localhost` | N
 `NEUTRON_RABBITMQ_USER` | | `guest` | N
 `NEUTRON_RABBITMQ_PASS` | | `guest` | N
 `NEUTRON_BRIDGE_MAPPINGS` | | `external:br-ex` | N

## Examples

    docker run -d \
        --restart=on-failure:10 \
        --privileged=true \
         --volume=/lib/modules:/lib/modules:ro \
        --name "$NOVA_COMPUTE_HOSTNAME" \
        --hostname "$NOVA_COMPUTE_HOSTNAME" \
        --env NOVA_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
        --env NOVA_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
        --env NOVA_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
        --env NOVA_MEMCACHED_SERVERS="$MEMCACHED_SERVERS" \
        --env NOVA_IDENTITY_URI="$IDENTITY_URI" \
        --env NOVA_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
        --env NOVA_SERVICE_USER="$NOVA_SERVICE_USER" \
        --env NOVA_SERVICE_PASS="$NOVA_SERVICE_PASS" \
        --env NOVA_GLANCE_API_URLS="http://$GLANCE_API_HOSTNAME:9292" \
        --env NOVA_NEUTRON_SERVER_URL="http://$NEUTRON_SERVER_HOSTNAME:9696" \
        --env NOVA_IRONIC_API_ENDPOINT="http://$IRONIC_API_HOSTNAME:6385/v1" \
        --env NOVA_USE_IRONIC="true" \
        --env NOVA_IRONIC_SERVICE_USER="$IRONIC_SERVICE_USER" \
        --env NOVA_IRONIC_SERVICE_PASS="$IRONIC_SERVICE_PASS" \
        --env NOVA_IRONIC_AUTH_URI="$AUTH_URI" \
        --env NOVA_IRONIC_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
        --env NOVA_NOTIFY_ON_STATE_CHANGE="vm_and_task_state" \
        --env NOVA_NOTIFICATIONS="true" \
        --env NEUTRON_IDENTITY_URI="$IDENTITY_URI" \
        --env NEUTRON_SERVICE_TENANT_NAME="$SERVICE_TENANT_NAME" \
        --env NEUTRON_SERVICE_USER="$NOVA_SERVICE_USER" \
        --env NEUTRON_SERVICE_PASS="$NOVA_SERVICE_PASS" \
        --env NEUTRON_RABBITMQ_HOST="$RABBITMQ_HOSTNAME" \
        --env NEUTRON_RABBITMQ_USER="$NOVA_RABBITMQ_USER" \
        --env NEUTRON_RABBITMQ_PASS="$NOVA_RABBITMQ_PASS" \
         os-nova-compute
