#!/usr/bin/env python

# Create a new rabbitmq user:
#
# docker exec -i rabbitmq.os-in-a-box \
#   rabbitmqctl add_user notification moocai9bohQue5aiNier
# docker exec -i rabbitmq.os-in-a-box \
#   rabbitmqctl set_permissions notification ".*" ".*" ".*"

from oslo_config import cfg
import oslo_messaging
from oslo_messaging.notify import filter

import pprint
import logging


logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger(__name__)


class NotificationEndpoint(object):
    #filter = NotificationFilter(publisher_id='^compute.*')

    def error(self, ctxt, publisher_id, event_type, payload, metadata):
        LOG.error("Somewhere something went wrong!")

    def warning(self, ctxt, publisher_id, event_type, payload, metadata):
        LOG.error("This is 'just' a warning!")

    def info(self, ctxt, publisher_id, event_type, payload, metadata):
        if event_type == "compute.instance.update":
            node = payload.get("node")
            if node is None:
                LOG.debug("Node is None for instance_update()")
                return

            old_state = payload.get("old_state")
            state = payload.get("state")
            old_task_state = payload.get("old_task_state")
            new_task_state = payload.get("new_task_state")
            timestamp = metadata['timestamp']

            if old_state == "building" and state == "building" and \
                           old_task_state is None and new_task_state is None:
                LOG.info(
                    "*** [{0} UTC] Deploy of node {1} "
                    "has just started".format(timestamp, node))
            elif old_state == "active" and state == "active" and \
                           old_task_state is None and new_task_state is None:
                LOG.info(
                    "*** [{0} UTC] Node {1} is now active "
                    "(rebuild)".format(timestamp, node))
            elif old_state == "building" and state == "active" and \
                    old_task_state == "spawning" and new_task_state is None:
                LOG.info(
                   "*** [{0} UTC] Node {1} is now active "
                   "(first deploy)".format(timestamp, node))
            elif old_task_state == "deleting" and new_task_state == "deleting":
                LOG.info(
                   "*** [{0} UTC] Deletion of node {1} "
                   "has just started".format(timestamp, node))
            elif old_task_state == "rebuild_spawning" and \
                           new_task_state == "rebuild_spawning":
                LOG.info(
                    "*** [{0} UTC] Node {1} is about to be "
                    "rebuilt".format(timestamp, node))


transport = oslo_messaging.get_transport(
    cfg.CONF,
    url="rabbit://notification:moocai9bohQue5aiNier@rabbitmq.os-in-a-box:5672/%2F"
)

targets = [oslo_messaging.Target(topic='notifications')]
endpoints = [NotificationEndpoint()]

server = oslo_messaging.get_notification_listener(
    transport, targets, endpoints)

server.start()
server.wait()
