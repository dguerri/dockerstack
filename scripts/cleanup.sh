#!/bin/bash

neutron net-delete external
nova flavor-list | awk '/ParallelsVM/ { print $2}' | xargs nova flavor-delete
glance image-list | awk '/\| [0-9a-f]/ { print $2}' | xargs glance image-delete
ironic node-list | awk '/\| [0-9a-f]/ { print $2}' | xargs ironic node-delete
