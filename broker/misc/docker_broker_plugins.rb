# Specifies which broker plugins to include when running the broker from source
# Installs to ~/.openshift/broker_plugins.rb
gem 'puma'
gem 'openshift-origin-dns-bind', :path => '../plugins/dns/bind'