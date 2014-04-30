# openshift-origin-broker
#
# To build, cd into the origin-server source directory and run:
# docker build -rm -t openshift-origin-broker .
#
# To run origin-broker:
# docker run -d -i -t -e "MONGO_HOST_PORT=<mongo_host_port>" -p <port_on_host>:443 openshift-origin-broker
# Where MONGO_HOST_PORT is the config value as defined in broker.conf and <port_on_host> is the port you want to map
# Any values defined in broker.conf can be overridden by passing additional -e flags during the run command, alternatively 
# you can modify the broker.conf file in your source and re-build instead of passing -e flags.
#
# To run oo-* admin commands:
# docker run -rm -i -t -e "MONGO_HOST_PORT=<mongo_host_port>" openshift-origin-broker /bin/bash
# Where MONGO_HOST_PORT is the config value as defined in broker.conf

FROM openshift/centos-ruby
MAINTAINER Jessica Forrester <jforrest@redhat.com>

# OpenShift RHEL6 repository to provide additional rubygems
ADD https://mirror.openshift.com/pub/openshift-origin/nightly/rhel-6/dependencies/openshift-rhel6-dependencies.repo /etc/yum.repos.d/openshift-rhel6-dependencies.repo

RUN yum install --enablerepo=openshift-deps-rhel6 --assumeyes \
     ruby193-rubygem-bson_ext \
     ruby193-rubygem-json \
     ruby193-rubygem-json_pure \
     ruby193-rubygem-mongo \
     ruby193-rubygem-mongoid \
     ruby193-rubygem-open4 \
     ruby193-rubygem-parseconfig \
     ruby193-rubygem-rest-client \
     ruby193-rubygem-systemu \
     ruby193-rubygem-xml-simple \
     ruby193-rubygem-bson \
     ruby193-rubygem-dnsruby \
     ruby193-rubygem-metaclass \
     ruby193-rubygem-moped \
     ruby193-rubygem-origin \
     ruby193-rubygem-state_machine \
     ruby193-rubygem-stomp \
     ruby193-rubygem-systemu \
     ruby193-rubygem-term-ansicolor \
     ruby193-rubygem-syslog-logger \
     && yum clean all # Clean up yum cache at the end.

# BROKER_SOURCE tells the broker to include gems based on source locations
ENV BROKER_SOURCE 1

# OPENSHIFT_ENABLE_ENV_CONFIG tells the broker to check for config values as environment variables before checking the broker.conf file
ENV OPENSHIFT_ENABLE_ENV_CONFIG 1

# APP_ROOT tells the prepare and run scripts where the Gemfile is located for bundler to install/exec
ENV APP_ROOT broker

# Add all necessary source from origin-server
ADD util /usr/sbin
ADD common /tmp/src/common
ADD admin-console /tmp/src/admin-console
ADD broker-util /tmp/src/broker-util
ADD plugins /tmp/src/plugins
ADD broker /tmp/src/broker
ADD controller /tmp/src/controller
ADD docker /tmp/src/docker

# Copy configuration files to expected locations
RUN mkdir -p ~/.openshift && cp /tmp/src/broker/misc/docker_broker_plugins.rb ~/.openshift/broker_plugins.rb
RUN mkdir -p /etc/openshift && cp -r /tmp/src/broker/conf/* /etc/openshift/
RUN cp /tmp/src/plugins/dns/bind/conf/openshift-origin-dns-bind.conf.example /etc/openshift/plugins.d/openshift-origin-dns-bind.conf
RUN cp /tmp/src/plugins/msg-broker/mcollective/conf/openshift-origin-msg-broker-mcollective.conf.example /etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf

# Install broker oo-* scripts
RUN cp /tmp/src/broker-util/oo-* /usr/sbin/ && chmod 750 /usr/sbin/oo-*
RUN cp /tmp/src/broker-util/lib/* /opt/rh/ruby193/root/usr/share/ruby/

RUN prepare
CMD run
