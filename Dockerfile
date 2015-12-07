# openshift-origin-broker
#
# To build, cd into the origin-server source directory and run:
# docker build --rm -t openshift-origin-broker .
#
# To run origin-broker:
# docker run -d -i -t -e "MONGO_HOST_PORT=<mongo_host_port>" -e "AUTH_SALT=<broker_auth_salt>" -p <port_on_host>:443 openshift-origin-broker
# Where MONGO_HOST_PORT and AUTH_SALT are the config values as defined in broker.conf and <port_on_host> is the port you want to map
# You can get an AUTH_SALT by running "openssl rand -base64 64"
# Any values defined in broker.conf can be overridden by passing additional -e flags during the run command, alternatively you can
# modify the broker.conf file in your source and re-build instead of passing -e flags.
#
# To run oo-* admin commands:
# docker run --rm -i -t -e "MONGO_HOST_PORT=<mongo_host_port>" -e "AUTH_SALT=<broker_auth_salt>" openshift-origin-broker /bin/bash --login
# Where MONGO_HOST_PORT and AUTH_SALT are the config values as defined in broker.conf

FROM centos
RUN yum -y install which gcc-c++ openssl-devel libyaml-devel readline-devel zlib-devel openssl  patch

# Install and setup ruby 1.9.3 using rvm and install bundler
RUN yum install -y centos-release-scl
RUN yum install -y scl-utils ruby193 ruby193-ruby-devel

# Setup default ssl key and cert
RUN openssl req -new -x509 -nodes -out /etc/pki/tls/certs/localhost.crt -keyout /etc/pki/tls/private/localhost.key -batch

# BROKER_SOURCE tells the broker to include gems based on source locations
ENV BROKER_SOURCE 1

# OPENSHIFT_ENABLE_ENV_CONFIG tells the broker to check for config values as environment variables before checking the broker.conf file
ENV OPENSHIFT_ENABLE_ENV_CONFIG 1

# Add all necessary source from origin-server
ADD util /usr/sbin
ADD common /var/www/openshift/common
ADD admin-console /var/www/openshift/admin-console
ADD broker-util /var/www/openshift/broker-util
ADD plugins /var/www/openshift/plugins
ADD broker /var/www/openshift/broker
ADD controller /var/www/openshift/controller

# Copy configuration files to expected locations
RUN mkdir -p ~/.openshift && cp /var/www/openshift/broker/misc/docker_broker_plugins.rb ~/.openshift/broker_plugins.rb
RUN mkdir -p /etc/openshift && cp -r /var/www/openshift/broker/conf/* /etc/openshift/
RUN cp /var/www/openshift/plugins/dns/bind/conf/openshift-origin-dns-bind.conf.example /etc/openshift/plugins.d/openshift-origin-dns-bind.conf
RUN cp /var/www/openshift/plugins/msg-broker/mcollective/conf/openshift-origin-msg-broker-mcollective.conf.example /etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf

# Install broker oo-* scripts
RUN cp /var/www/openshift/broker-util/oo-* /usr/sbin/ && chmod 750 /usr/sbin/oo-*
RUN cp /var/www/openshift/broker-util/lib/* /opt/rh/ruby193/root/usr/share/ruby
WORKDIR /var/www/openshift/broker
RUN scl enable ruby193 "bundle install"
CMD scl enable ruby193 "bundle exec rails s puma"
