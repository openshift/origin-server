# Specifies which broker plugins to include when running the broker from source
# Installs to ~/.openshift/broker_plugins.rb
gem 'mcollective-client', '~> 2.2.1'
gem 'puma'
gem 'openshift-origin-msg-broker-mcollective', :path => '../plugins/msg-broker/mcollective'
gem 'openshift-origin-dns-bind', :path => '../plugins/dns/bind'