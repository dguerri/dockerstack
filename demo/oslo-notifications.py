#!/usr/bin/env python

# Create a new rabbitmq user:
#
# docker exec -i rabbitmq.os-in-a-box \
#     rabbitmqctl add_user notification moocai9bohQue5aiNier
# docker exec -i rabbitmq.os-in-a-box \
#     rabbitmqctl set_permissions notification ".*" ".*" ".*"

import pprint

from oslo_config import cfg
import oslo_messaging
from oslo_messaging.notify import filter


class NotificationEndpoint(object):

    def info(self, ctxt, publisher_id, event_type, payload, metadata):
        print("***** info received for {0}".format(publisher_id))
        pprint.pprint(payload)

    def warn(self, ctxt, publisher_id, event_type, payload, metadata):
        print("***** warning received for {0}".format(publisher_id))
        pprint.pprint(payload)

    def error(self, ctxt, publisher_id, event_type, payload, metadata):
        print("***** error received for {0}".format(publisher_id))
        pprint.pprint(payload)

transport = oslo_messaging.get_transport(
    cfg.CONF,
    url="rabbit://notification:moocai9bohQue5aiNier@rabbitmq.os-in-a-box:5672/%2F"
)

targets = [
    oslo_messaging.Target(topic='notifications')
]
endpoints = [
    NotificationEndpoint(),
]
#pool = "eventlet"
server = oslo_messaging.get_notification_listener(
    transport, targets, endpoints)

server.start()
server.wait()
