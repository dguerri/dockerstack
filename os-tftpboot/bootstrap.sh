#!/bin/bash

set -u
set -x
set -e
set -o pipefail

cp /usr/lib/syslinux/pxelinux.0 /tftpboot
cp /usr/lib/syslinux/chain.c32 /tftpboot
cp /usr/lib/ipxe/undionly.kpxe /tftpboot

echo 'r ^([^/]) /tftpboot/\1' > /tftpboot/map-file
echo 'r ^(/tftpboot/) /tftpboot/\2' >> /tftpboot/map-file

in.tftpd $@
