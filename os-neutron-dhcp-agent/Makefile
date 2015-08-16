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

current_dir := $(shell basename $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
BUILD_VERSION ?= latest

all: build

build:
	@docker build --rm --tag=$(current_dir):$(BUILD_VERSION) . > /dev/null
	@echo "🔨  $(current_dir):$(BUILD_VERSION) - Done"

clean:
	@docker rmi -f $(current_dir):$(BUILD_VERSION) || true
	@echo "🔫  $(current_dir):$(BUILD_VERSION) - Done"

rebuild: clean build

test:
	@shellcheck bootstrap.sh
	@echo "😏  $(current_dir):$(BUILD_VERSION) - Passed"

.PHONY: all build clean test rebuild
