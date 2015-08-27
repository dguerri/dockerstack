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

CACHE_TIMEOUT = 3600
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


def memcache_me(salt=""):
    def r_memcache_me(decorated_func):
        def inner(self, key):
            cache_key = "{0}|{1}".format(salt, key)
            try:
                value = MEMCACHED_CLIENT.get(cache_key)
                if value is None:
                    LOG.debug("cache miss!")
                    value = decorated_func(self, key)
                    MEMCACHED_CLIENT.set(cache_key, value, time=CACHE_TIMEOUT)
                return value
            except Exception as e:
                LOG.error("Something went wrong while using the memcached "
                    "server: {0}".format(e))
                return decorated_func(self, key)

        if MEMCACHED_CLIENT is None:
            LOG.debug("Memcached support is disabled")
            return decorated_func
        return inner

    return r_memcache_me


class IronicClientWrapper(object):

    MEMCACHE_PREFIX = "IronicClientWrapper"

    def __init__(self, **kwargs):
        self.ironic_client = ironic_client.get_client(
            api_version=1, **kwargs)

    @memcache_me(MEMCACHE_PREFIX)
    def node_name(self, node_id):
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
