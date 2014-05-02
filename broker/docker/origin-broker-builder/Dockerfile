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

# Display STI usage when invoked outside STI builder
#
CMD ["/usr/bin/usage"]
