## Clean

    # Clean version 1.0 with 5 parallel processes
    make clean -j5 BUILD_VERSION=1.0

## Test

    # Test version 1.0 with 5 parallel processes
    make test -j5 BUILD_VERSION=1.0

### Example output

    (davide:marley)-[0]-(~/D/openstack-docker) # make test 
    ☝️  os-mysql:latest - Not implemented
    ☝️  os-httpboot:latest - Not implemented
    ☝️  os-tftpboot:latest - Not implemented
    ☝️  os-rabbitmq:latest - Not implemented
    ☝️  os-memcached:latest - Not implemented
    ✅  os-keystone:latest - Passed
    ✅  os-glance-registry:latest - Passed
    ✅  os-glance-api:latest - Passed
    ✅  os-neutron-server:latest - Passed
    ✅  os-nova-conductor:latest - Passed
    ✅  os-nova-api:latest - Passed
    ✅  os-nova-scheduler:latest - Passed
    ✅  os-nova-compute:latest - Passed
    ✅  os-neutron-dhcp-agent:latest - Passed
    ✅  os-ironic-conductor:latest - Passed
    ✅  os-ironic-api:latest - Passed
    ✅  os-swift-proxy:latest - Passed
    ✅  os-swift-account:latest - Passed
    ✅  os-swift-object:latest - Passed
    ✅  os-swift-container:latest - Passed
    ☝️  os-base-image:latest - Not implemented

## Build

    # Build "latest"  (docker caches FS layers, so don't use parallel builds)
    make all

    # Build version 1.0
    make all BUILD_VERSION=1.0

### Example output

    (davide:marley)-[0]-(~/D/openstack-docker) # make
    🔨  os-base-image:latest - Done
    🔨  os-mysql:latest - Done
    🔨  os-httpboot:latest - Done
    🔨  os-tftpboot:latest - Done
    🔨  os-rabbitmq:latest - Done
    🔨  os-memcached:latest - Done
    🔨  os-keystone:latest - Done
    🔨  os-glance-registry:latest - Done
    🔨  os-glance-api:latest - Done
    🔨  os-neutron-server:latest - Done
    🔨  os-nova-conductor:latest - Done
    🔨  os-nova-api:latest - Done
    🔨  os-nova-scheduler:latest - Done
    🔨  os-nova-compute:latest - Done
    🔨  os-neutron-dhcp-agent:latest - Done
    🔨  os-ironic-conductor:latest - Done
    🔨  os-ironic-api:latest - Done
    🔨  os-swift-proxy:latest - Done
    🔨  os-swift-account:latest - Done
    🔨  os-swift-object:latest - Done
    🔨  os-swift-container:latest - Done

## Run

    (davide:marley)-[0]-(~/D/openstack-docker) # ./start-the-mall.sh 
    + set -e
    + set -u
    + set -o pipefail
    +++ dirname ./start-the-mall.sh
    ++ cd .
    ++ pwd
    + SCRIPT_DIR=/Users/davide/Developer/openstack-docker
    + DOCKER_SERVER_HOSTNAME=docker-server.local
    + DOCKER_SERVER_EXTERNAL_IP=10.29.29.1

_a lot of stuff_

    + docker exec -i autodns.os-in-a-box nc -w1 -z glance-api.os-in-a-box 9292
    + ret=0
    + set -e
    + '[' 0 -eq 0 ']'
    + return 0
    (davide:marley)-[0]-(~/D/openstack-docker) # 


Then run `scripts/connect_external_net.sh` to attach eth1 (an external physical interface) to the provisioning network.
This also creates a virtual switch and a couple of veth interfaces. Il also "pushes" one of the 2 veth interface in the `neutron-dhcp-agent` container.

This is the final (virtual) networking configuration

    ┌────────────────────────────────────────────────────────────┐
    │┌──────────────────────────────────────────────────────────┐│
    ││                         docker0                          ││
    │└──────────────────────────────────────────────────────────┘│
    │             │                           │                  │
    │             │                           │                  │
    │┌─────────────────────────┐              │                  │
    ││   Neutron DHCP Agent    │    ┌──────────────────┐         │
    ││        Container        │    │ ┌────────────────┴─┐       │
    ││                         │    │ │ ┌────────────────┴─┐     │
    ││┌───────────────────────┐│    │ │ │ ┌────────────────┴─┐   │
    │││         br-ex ┌──────┐││    │ │ │ │ Other containers │   │
    ││└───────────────┤ ext1 ├┘│    └─┤ │ │                  │   │
    ││                └──────┘ │      └─┤ │                  │   │
    ││                    │    │        └─┤                  │   │
    │└────────────────────┼────┘          └──────────────────┘   │
    │                     │                                      │
    │                 ┌──────┐    ┌────────────────────────┐     │
    │                 │ ext0 │────│      provisioning      │     │
    │                 └──────┘    └────────────────────────┘     │
    │                                          │                 │
    │                                          │                 │
    │             ┌──────┐                 ┌──────┐              │
    └─────────────┤ eth0 ├─────────────────┤ eth1 ├──────────────┘
                  └──────┘                 └──────┘               
                                               │                  
                                               │                  
    ┌────────────────────────────────────────────────────────────┐
    │                      physical network                      │
    └────────────────────────────────────────────────────────────┘
           │               │               │               │      
           │               │               │               │      
    ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
    │            │  │            │  │            │  │            │
    │  BM node   │  │  BM node   │  │  BM node   │  │  BM node   │
    │            │  │            │  │            │  │            │
    └────────────┘  └────────────┘  └────────────┘  └────────────┘

Lastly run `scripts/setup_openstack.sh` to create the initial demo setup for BM provisioning.
