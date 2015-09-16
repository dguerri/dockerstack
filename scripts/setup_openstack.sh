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

DOWNLOAD_DIR="$HOME/downloads"

CIDR="10.29.29.0/24"
GATEWAY="10.29.29.1"
START_IP="10.29.29.20"
END_IP="10.29.29.200"
DNS="10.29.29.1"

IMAGES=(
    "http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img"
    "https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-amd64-disk1.img"
    "https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"
    "https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-22-20150521.x86_64.qcow2"
)

# -------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

download_if_not_exists() {
    local url="$1"
    local filename="$(basename $1)"

    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir "$DOWNLOAD_DIR"
    fi

    if [ ! -f "$DOWNLOAD_DIR/$filename" ]; then
        curl -L -s -o "$DOWNLOAD_DIR/$filename" "$url"
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

for image in "${IMAGES[@]}"; do
    download_if_not_exists "$image"

    image_basename="$(basename $image)"
    image_name="${image_basename%.*}"

    openstack image create \
        --public \
        --container-format bare \
        --disk-format qcow2 \
        --file "$DOWNLOAD_DIR/$image_basename" \
        "$image_name"
done

# -- [ Nova Key Pair
nova keypair-add --pub-key ~/.ssh/id_rsa.pub keyp1

# -- [ Nova default secgroup rules
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
