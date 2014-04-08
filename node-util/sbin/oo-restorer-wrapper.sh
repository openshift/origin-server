#!/bin/bash

# Use dbus-send instead of oddjob_request so that we can specify
# a timeout.  See Bug 1085489.

exec /bin/dbus-send --system --dest=com.redhat.oddjob_openshift --print-reply --reply-timeout=600000 /com/redhat/oddjob/openshift com.redhat.oddjob_restorer.restore "string:$1"

#/usr/bin/oddjob_request -s com.redhat.oddjob_openshift -o /com/redhat/oddjob/openshift -i com.redhat.oddjob_restorer restore $1
