FROM openshift/ruby-19-centos
MAINTAINER Jessica Forrester <jforrest@redhat.com>

# OpenShift RHEL6 repository to provide additional rubygems
ADD https://mirror.openshift.com/pub/openshift-origin/nightly/rhel-6/dependencies/openshift-rhel6-dependencies.repo /etc/yum.repos.d/openshift-rhel6-dependencies.repo

# switch to root for yum installs, ruby-19-centos left the user as "ruby"
USER root

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
     ruby193-rubygem-puma \
     ruby193-rubygem-poltergeist \
     ruby193-rubygem-httpclient \
     ruby193-rubygem-netrc \
     ruby193-rubygem-mocha \
     ruby193-rubygem-simplecov \
     ruby193-rubygem-minitest \
     ruby193-rubygem-nokogiri \
     ruby193-rubygem-safe_yaml \
     ruby193-rubygem-state_machine \
     ruby193 \
     && yum update -y && yum clean all # Clean up yum cache at the end.

# These are necessary so we can run as the ruby user
# TODO fix logging to not user /var/log/openshift
RUN mkdir -p /etc/openshift && \
    chown ruby:ruby /etc/openshift && \
    echo 'export PATH=$PATH:/opt/ruby/bin' >> /opt/ruby/.bashrc && \
    mkdir -p /var/log/openshift/broker && \
    chown -R ruby:ruby /var/log/openshift

USER ruby

# BROKER_SOURCE tells the broker to include gems based on source locations
ENV BROKER_SOURCE 1

# OPENSHIFT_ENABLE_ENV_CONFIG tells the broker to check for config values as environment variables before checking the broker.conf file
ENV OPENSHIFT_ENABLE_ENV_CONFIG 1

# Broker is not installed in the previous default location
ENV OPENSHIFT_BROKER_DIR /opt/ruby/src/broker

# APP_ROOT tells the prepare and run scripts where the Gemfile is located for bundler to install/exec
ENV APP_ROOT broker


# Display STI usage when invoked outside STI builder
#
CMD ["/usr/bin/usage"]
