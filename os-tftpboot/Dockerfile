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

FROM ubuntu:14.04
MAINTAINER Davide Guerri <davide.guerri@gmail.com>

RUN set -x \
    && apt-get -y install tftpd-hpa

VOLUME /tftpboot

RUN touch /tftpboot/map-file

EXPOSE 69/udp

ENTRYPOINT ["in.tftpd"]
CMD ["-L", "--verbose", "-m", "/tftpboot/map-file", "-u", "tftp", "--secure", "/tftpboot"]
