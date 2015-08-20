#!/bin/bash

set -u
set -x
set -e
set -o pipefail

touch /tftpboot/map-file
in.tftpd $@
