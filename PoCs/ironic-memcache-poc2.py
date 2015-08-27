#!/usr/bin/env python

import logging
import os
import sys

from ironicclient import client as ironic_client
from ironicclient.openstack.common.apiclient import exceptions as \
    ironic_exceptions

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger(__name__)


try:
    import memcache
except ImportError as e:
    USE_MEMCACHE = False
    LOG.debug("Memcached support disabled: '{0}'".format(e))
else:
    LOG.debug("Memcached support enabled")
    USE_MEMCACHE = True

CACHE_TIMEOUT = 60
MEMCACHED_SERVERS = ["memcached.os-in-a-box:11211"]

if USE_MEMCACHE and MEMCACHED_SERVERS is not None:
    try:
        MEMCACHED_CLIENT = memcache.Client(
            MEMCACHED_SERVERS, debug=0)
        LOG.debug("Memcached support enabled")
    except Exception as e:
        LOG.error("Error getting the memcache client: {0}".format(e))
        MEMCACHED_CLIENT = None
else:
    LOG.debug("Memcached support is disabled")
    MEMCACHED_CLIENT = None


class IronicClientWrapper(object):

    MEMCACHE_PREFIX = "this_is_sparta"

    def __init__(self, **kwargs):
        self.ironic_client = ironic_client.get_client(
            api_version=1, **kwargs)

    def cache_node_list(self):
        try:
            node_list = self.ironic_client.node.list(detail=True)
            for node in node_list:
                key = "{0}|{1}".format(self.MEMCACHE_PREFIX, node.uuid)
                MEMCACHED_CLIENT.set(key, node.name, time=CACHE_TIMEOUT)
        except Exception as e:
            LOG.error("Problem caching the list of nodes")

    def node_name(self, node_id):
        key = "{0}|{1}".format(self.MEMCACHE_PREFIX, node_id)
        try:
            value = MEMCACHED_CLIENT.get(key)
            if value is None:
                self.cache_node_list()
            return MEMCACHED_CLIENT.get(key)
        except Exception as e:
            LOG.error("Something went wrong '{0}'".format(e))
            try:
                return self.ironic_client.node.get(node_id).name
            except ironic_exceptions.NotFound as e:
                LOG.error("Node '{0}' not found!".format(node_id))
                return


def main():
    kwargs = {
        "os_username": os.getenv("OS_USERNAME", "admin"),
        "os_password": os.getenv("OS_PASSWORD", "password"),
        "os_auth_url": os.getenv("OS_AUTH_URL", "http://127.0.0.1:5000/v2.0"),
        "os_tenant_name": os.getenv("OS_TENANT_NAME", "admin"),
        "os_region_name": os.getenv("OS_REGION_NAME", "regionOne")
    }

    if len(sys.argv) != 2:
        LOG.error("Missing node id!")
        exit(1)

    client = IronicClientWrapper(**kwargs)

    node_id = sys.argv[1]
    node_name = client.node_name(node_id)

    if node_name is not None:
        LOG.info("Node name: '{0}'".format(node_name))

if __name__ == "__main__":
    main()
