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

FROM os-base-image
MAINTAINER Davide Guerri <davide.guerri@gmail.com>

# install packages
RUN set -x \
    && apt-get -y install \
        neutron-plugin-ml2 \
        neutron-plugin-openvswitch-agent \
        neutron-dhcp-agent \
    && apt-get -y clean \
    && rm -f /var/lib/neutron/neutron.sqlite

# copy config files
COPY dhcp_agent.ini /etc/neutron/dhcp_agent.ini
COPY ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
COPY neutron.conf /etc/neutron/neutron.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh && chmod a+x /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
