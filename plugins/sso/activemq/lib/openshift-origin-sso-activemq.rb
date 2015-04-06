module OpenShift
  module ActiveMQSsoModule
    require 'activemq_sso_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/activemq_sso_plugin.rb"
