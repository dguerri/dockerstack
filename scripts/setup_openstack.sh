#!/bin/bash

CIDR="10.29.29.0/24"
GATEWAY="10.29.29.1"
START_IP="10.29.29.20"
END_IP="10.29.29.200"
DNS="8.8.8.8"

neutron net-create \
    --shared \
    --router:external \
    --provider:network_type flat \
    --provider:physical_network external \
    external

neutron subnet-create \
    --name external \
    --gateway "$GATEWAY"\
    --allocation-pool "start=$START_IP,end=$END_IP" \
    --enable-dhcp \
    --dns-nameserver $DNS \
    external \
    $CIDR

glance image-create \
    --name='Cirros 0.3.4 - amd64' \
    --is-public=true \
    --container-format=bare \
    --disk-format=qcow2 \
    --progress \
    --location http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
