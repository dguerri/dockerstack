#! /usr/bin/env bash

set -uxeo pipefail

if [ ! -d  /pxe/tftpboot ]; then
    mkdir -p /pxe/tftpboot
fi
if [ ! -d  /pxe/httpboot ]; then
    mkdir -p /pxe/httpboot
fi
cp /usr/lib/syslinux/pxelinux.0 /pxe/tftpboot
cp /usr/lib/syslinux/chain.c32 /pxe/tftpboot
cp /usr/lib/ipxe/undionly.kpxe /pxe/tftpboot

cat <<EOF >/pxe/tftpboot/map-file
re ^(/pxe/tftpboot/) /pxe/tftpboot/\2
re ^/pxe/tftpboot/ /pxe/tftpboot/
re ^(^/) /pxe/tftpboot/\1
re ^([^/]) /pxe/tftpboot/\1
EOF

in.tftpd $@
