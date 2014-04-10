# rsyslog-openshift-plugin
OpenShift metadata message modification module for rsyslog. This plugin adds information about the OpenShift container to the message.

This plugin only works if the message has the $!uid JSON property, which can be added automatically via the imuxsock plugin by turning on the following 3 options:

- SysSock.UsePIDFromSystem
- SysSock.ParseTrusted
- SysSock.Annotate

# Operation
This plugin examines each message's $!uid JSON property. If the property exists and is greater than or equal to gearUidStart, the plugin will attempt to retrieve the following metadata for the gear (this is the default list and can be configured):

- OPENSHIFT_GEAR_UUID
- OPENSHIFT_APP_UUID
- OPENSHIFT_NAMESPACE
- OPENSHIFT_APP_NAME

The plugin will create the $!OpenShift subtree in the message's JSON and add keys corresponding to each of the gear's metadata items listed above. For example, with the default configuration:

- $!OpenShift!OPENSHIFT_GEAR_UUID
- $!OpenShift!OPENSHIFT_APP_UUID
- $!OpenShift!OPENSHIFT_NAMESPACE
- $!OpenShift!OPENSHIFT_APP_NAME

# Configuration
**gearUidStart** - the first user ID to be used for OpenShift gears (default: 1000)

**gearBaseDir** - the base directory where OpenShift gears reside (default: "/var/lib/openshift")

**maxCacheSize** - the maximum number of elements to store in the in-memory cache (default: 100)

**metadata** - an array listing which of a gear's metadata items to retrieve (default: ["OPENSHIFT_GEAR_UUID", "OPENSHIFT_APP_UUID", "OPENSHIFT_NAMESPACE", "OPENSHIFT_APP_NAME"])

# Installing the plugin
Requires the new (v6+) configuration file format. Tested with rsyslog 7.4.7.

1. Apply the patch 'rsyslog-openshift.patch' to the source of rsyslog:

        cd path/to/rsyslog
        patch -p1 -i rsyslog-openshift.patch

1. Copy the mmopenshift directory to rsyslog's plugins directory.
1. Update autotools files:

        cd path/to/rsyslog
        autogen.sh --enable-mmopenshift ...

1. make && make install

# Sample Configuration

        module(load="imuxsock" SysSock.Annotate="on" SysSock.ParseTrusted="on" SysSock.UsePIDFromSystem="on")

        template(name="OpenShift" type="list") {
                property(name="timestamp" dateFormat="rfc3339")
                constant(value=" ")
                property(name="hostname")
                constant(value=" ")
                property(name="syslogtag")
                constant(value=" app=")
                property(name="$!OpenShift!OPENSHIFT_APP_NAME")
                constant(value=" ns=")
                property(name="$!OpenShift!OPENSHIFT_NAMESPACE")
                constant(value=" appUuid=")
                property(name="$!OpenShift!OPENSHIFT_APP_UUID")
                constant(value=" gearUuid=")
                property(name="$!OpenShift!OPENSHIFT_GEAR_UUID")
                property(name="msg" spifno1stsp="on")
                property(name="msg" droplastlf="on")
                constant(value="\n")
        }

        module(load="mmopenshift")
        action(type="mmopenshift")
        if $!OpenShift!OPENSHIFT_APP_UUID != '' then
          *.* action(type="omfile" file="/var/log/openshift_gears" template="OpenShift")
        else {
          *.info;mail.none;authpriv.none;cron.none      action(type="omfile" file="/var/log/messages")
          ...
        }


# License
Copyright 2014 Red Hat, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
