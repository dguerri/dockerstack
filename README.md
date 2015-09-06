## A picture is worth a thousand words

![A picture is worth a thousand words](doc/demo.png)

## Prerequisites

 * [Docker](https://www.docker.com) 1.6.0 or later

 * [docker-py](https://github.com/docker/docker-py) version 1.2.3 on the ansible server running the playbook
 * [MySQL-python](https://pypi.python.org/pypi/MySQL-python) on the ansible server running the playbook
 * OpenStack python clients for Keystone, Glance, Neutron, Swift, Ironic and Nova on the ansible server running the playbook

        pip install python-{keystone,neutron,ironic,nova,glance,swift}client docker-py==1.2.3 MySQL-python
    

If you are using an Ubuntu box, above requirements require in turn:

    apt-get install libmysqlclient-dev libxml2-dev libxslt1-dev


If you are going to build the containers behind a proxy (_not recommended_), you will have to tweak both the Docker default configuration file and the os-base-image Dockerfile. [Here](http://nknu.net/running-docker-behind-a-proxy-on-ubuntu-14-04/) is a good guide about that.

## Clean

    # Clean version 1.0 with 5 parallel processes
    make clean -j5 BUILD_VERSION=1.0

## Test

Testing requires [shellcheck](http://www.shellcheck.net/about.html) 1.3.8 or later.

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

    # Build "latest"
    make all

    # Build version 1.0
    make all BUILD_VERSION=1.0

### Example output

    (davide:marley)-[0]-(~/D/openstack-docker) # make all
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

## Run the demo

### Please note
Please keep in mind that the "interesting" things here are the Dockerfiles, not the demo. The demo shows just _one_ possible way to use container images that are built with the previous command and it is very dependent on the hardware I used to develop it.

Also, in a production environment you may want to distribute your containers on multiple servers and use an external DNS server keeping track of the needed aliases ("service names" -> docker server). You may want to use a DNS service with an API service orchestrated with Ansible, for instance.

The included Ansible playbook also creates a number of data containers to demonstrate how data can be persisted across upgrades while preserving portability.

### Demo
The included demo consists of an Ansible playbook and 2 shell scripts. It is designed for Parallels Desktop and requires an unprovisioned virtual machine with one NIC with MAC address `00:1C:42:89:64:34`.

The demo also uses [autodns](https://github.com/rehabstudio/docker-autodns) from rehabstudio. This is not a strict requirement for the proposed infrastructure so you can use your preferred DNS, as long as it can be configured dynamically during the creation of containers. 

Using Ansible to configure an external DNS or even using Avahi daemon are possible alternatives.

For the sake of this demo, as described [here](https://github.com/rehabstudio/docker-autodns#prerequisites), the docker daemon should be started with the following parameters:

        DOCKER_OPTS="--bip=172.17.42.1/16 --dns=172.17.42.1 --dns=<your resolver1> [--dns=<your resolver2> [...]]"

 Add `nameserver 127.0.0.1` on top of the resolv.conf file running the docker server.

__Run the demo:__

1. Run `ansible-playbook`:

        ~# cd ansible
        ~# time ansible-playbook -i inventory/docker_server site.yml

 After a successful play, you should have the following list of containers (output of `docker ps -a`, edited):

        IMAGE                   PORTS                      NAMES
        os-glance-api           0.0.0.0:9292->9292/tcp     glance-api.os-in-a-box
        os-glance-registry      9191/tcp                   glance-registry.os-in-a-box
        os-swift-proxy          0.0.0.0:8080->8080/tcp     swift-proxy.os-in-a-box
        os-swift-object         6000/tcp                   swift-object.os-in-a-box
        os-swift-container      6001/tcp                   swift-container.os-in-a-box
        os-swift-account        6002/tcp                   swift-account.os-in-a-box
        os-base-image                                      swift-devs-data
        os-base-image                                      swift-rings-data
        os-nova-compute                                    nova-compute.os-in-a-box
        os-nova-scheduler                                  nova-scheduler.os-in-a-box
        os-nova-api             0.0.0.0:8774->8774/tcp     nova-api.os-in-a-box
        os-nova-conductor                                  nova-conductor.os-in-a-box
        os-neutron-dhcp-agent                              neutron-dhcp-agent.os-in-a-box
        os-neutron-server       0.0.0.0:9696->9696/tcp     neutron-server.os-in-a-box
        os-ironic-api           0.0.0.0:6385->6385/tcp     ironic-api.os-in-a-box
        os-ironic-conductor                                ironic-conductor.os-in-a-box
        os-httpboot             0.0.0.0:8090->80/tcp       ipxe-httpd.os-in-a-box
        os-tftpboot             0.0.0.0:69->69/udp         pxe-tftp.os-in-a-box
        os-base-image                                      pxe-boot-data
        os-rabbitmq             5672/tcp                   rabbitmq.os-in-a-box
        os-keystone             0.0.0.0:5000->5000/tcp,    keystone.os-in-a-box
                                0.0.0.0:35357->35357/tcp
        os-mysql                3306/tcp                   mysql.os-in-a-box
        os-base-image                                      mysql-data
        os-memcached            11211/tcp                  memcached.os-in-a-box
        rehabstudio/autodns     0.0.0.0:53->53/udp         autodns.os-in-a-box

2. run `scripts/connect_external_net.sh` to attach `eth1` (an external physical interface) to the provisioning network.
This also creates a virtual switch and a couple of veth interfaces. Il also "pushes" one of the 2 veth interface in the `neutron-dhcp-agent` container.

 The following picture shows the final (virtual) networking configuration after running `scripts/connect_external_net.sh`:

        ┌──────────────────────────────────────────────────┐   ┌─┐ ┌───────┐
        │ ┌────────────────────────────────────────────┐   │   │ │─│BM node│
        │ │                  docker0                   │   │   │p│ └───────┘
        │ └────────────────────────────────────────────┘   │   │h│          
        │           │                       │              │   │y│          
        │           │                       │              │   │s│          
        │┌────────────────────┐    ┌────────────────┐      │   │i│ ┌───────┐
        ││ Neutron DHCP Agent │    │ ┌──────────────┴─┐    │   │c│─│BM node│
        ││     Container      │    │ │ ┌──────────────┴─┐  │   │a│ └───────┘
        ││┌──────────────────┐│    │ │ │ ┌──────────────┴─┐│   │l│          
        │││      br-ex┌────┐ ││    │ │ │ │Other containers││   │-│          
        ││└───────────┤ext1├─┘│    └─┤ │ │                ││   │n│          
        ││            └────┘  │      └─┤ │                ││   │e│          
        ││               │    │        └─┤                ││   │t│          
        │└───────────────┼────┘          └────────────────┘│   │w│          
        │                │                                 │   │o│          
        │             ┌────┐      ┌───────────────┐     ┌──┴─┐ │r│ ┌───────┐
        │             │ext0│──────│ provisioning  │─────│eth1│─│k│─│BM node│
        │     ┌────┐  └────┘      └───────────────┘     └──┬─┘ │ │ └───────┘
        └─────┤eth0├───────────────────────────────────────┘   └─┘          
              └────┘                                                        

3. run `scripts/setup_openstack.sh` to create the initial demo setup for BM provisioning.

