FROM openshift/ruby-19-centos
MAINTAINER Jessica Forrester <jforrest@redhat.com>

# OpenShift RHEL6 repository to provide additional rubygems
ADD https://mirror.openshift.com/pub/openshift-origin/nightly/rhel-6/dependencies/openshift-rhel6-dependencies.repo /etc/yum.repos.d/openshift-rhel6-dependencies.repo

# switch to root for yum installs, ruby-19-centos left the user as "ruby"
USER root

RUN yum install --enablerepo=openshift-deps-rhel6 --assumeyes \
     ruby193-rubygem-coffee-rails \
     ruby193-rubygem-compass-rails \
     ruby193-rubygem-formtastic \
     ruby193-rubygem-haml \
     ruby193-rubygem-jquery-rails \
     ruby193-rubygem-minitest \
     ruby193-rubygem-rails \
     ruby193-rubygem-rdiscount \
     ruby193-rubygem-sass-rails \
     ruby193-rubygem-sass-twitter-bootstrap \
     ruby193-rubygem-uglifier \
     ruby193-rubygem-syslog-logger \
     ruby193-rubygem-sprockets \
     ruby193-rubygem-therubyracer \
     ruby193-rubygem-puma \
     ruby193-rubygems-devel \
     ruby193 \
     && yum update -y && yum clean all # Clean up yum cache at the end.

# These are necessary so we can run as the ruby user
# TODO fix logging to not user /var/log/openshift
RUN mkdir -p /etc/openshift && \
    chown ruby:ruby /etc/openshift && \
    echo 'export PATH=$PATH:/opt/ruby/bin' >> /opt/ruby/.bashrc && \
    mkdir -p /var/log/openshift/console && \
    chown -R ruby:ruby /var/log/openshift

USER ruby

# CONSOLE_PATH tells the console where the location of the rubygem-openshift-origin-console is
ENV CONSOLE_PATH /opt/ruby/src/console

# OPENSHIFT_ENABLE_ENV_CONFIG tells the console to check for config values as environment variables before checking the console.conf file
ENV OPENSHIFT_ENABLE_ENV_CONFIG 1

# Tell openshift-console to include the puma gem
ENV PUMA 1

# APP_ROOT tells the prepare and run scripts where the Gemfile is located for bundler to install/exec
ENV APP_ROOT openshift-console


# Display STI usage when invoked outside STI builder
#
CMD ["/usr/bin/usage"]
