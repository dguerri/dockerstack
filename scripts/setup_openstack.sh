#! /usr/bin/env bash
#
# Copyright (c) 2015 Davide Guerri <davide.guerri@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -uexo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CIDR="10.29.29.0/24"
GATEWAY="10.29.29.1"
START_IP="10.29.29.20"
END_IP="10.29.29.200"
DNS="10.29.29.1"

download_if_not_exists() {
    local url="$1"
    local filename=$(basename $1)

    if [ ! -f "$SCRIPT_DIR/$filename" ]; then
        curl -s -o "$SCRIPT_DIR/$filename" "$url"
    fi
}

# -- [ Neutron
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
    --dns-nameserver "$DNS" \
    external \
    "$CIDR"

# -- [ Glance
download_if_not_exists \
    http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
download_if_not_exists \
    https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-amd64-disk1.img
download_if_not_exists \
    http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe.vmlinuz
download_if_not_exists \
    http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe_image-oem.cpio.gz

openstack image create \
    --public \
    --container-format bare \
    --disk-format qcow2 \
    --file "$SCRIPT_DIR/cirros-0.3.4-x86_64-disk.img" \
    "Cirros 0.3.4 - x86_64"

openstack image create \
    --public \
    --container-format bare \
    --disk-format qcow2 \
    --file "$SCRIPT_DIR/vivid-server-cloudimg-amd64-disk1.img" \
    "Ubuntu Vivid - x86_64"

# -- [ Nova Key Pair
nova keypair-add --pub-key ~/.ssh/id_rsa.pub keyp1

# -- [ Nova default secgroup rules
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
