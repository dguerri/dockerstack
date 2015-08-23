#!/bin/bash

set -u
set -x
set -e
set -o pipefail

if [ ! -d  /pxe/tftpboot ]; then
    mkdir -p /pxe/tftpboot
fi
if [ ! -d  /pxe/httpboot ]; then
    mkdir -p /pxe/httpboot
fi
cp /usr/lib/syslinux/pxelinux.0 /pxe/tftpboot
cp /usr/lib/syslinux/chain.c32 /pxe/tftpboot
cp /usr/lib/ipxe/undionly.kpxe /pxe/tftpboot

echo 'r ^([^/]) /tftpboot/\1' > /pxe/tftpboot/map-file
echo 'r ^(/tftpboot/) /tftpboot/\2' >> /pxe/tftpboot/map-file

in.tftpd $@
