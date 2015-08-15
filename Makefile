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

CONTAINERS :=	os-mysql \
				os-rabbitmq \
				os-keystone \
				os-glance-registry \
				os-glance-api \
				os-neutron-server
CLEAN_JOBS := $(addprefix clean-,${CONTAINERS})
BUILD_JOBS := $(addprefix build-,${CONTAINERS})
TEST_JOBS  := $(addprefix test-,${CONTAINERS})
BUILD_VERSION ?= latest

# build-os-base-image must be done before anything else
all:
	$(MAKE) build-os-base-image
	$(MAKE) ${BUILD_JOBS}

clean: ${CLEAN_JOBS} clean-os-base-image

test: ${TEST_JOBS} build-os-base-image

build-os-base-image: ; $(MAKE) -C os-base-image build

clean-os-base-image: ; $(MAKE) -C os-base-image clean

test-os-base-image: ; $(MAKE) -C os-base-image test

${CLEAN_JOBS}: clean-%: ; $(MAKE) -C $* clean

${BUILD_JOBS}: build-%: ; $(MAKE) -C $* build

${TEST_JOBS}: test-%: ; $(MAKE) -C $* test

.PHONY: all ${CLEAN_JOBS} ${BUILD_JOBS} ${TEST_JOBS}
