require "openshift-origin-common"

module OpenShift
  module Controller
    require 'controller_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

#require "cloud_user"
require "openshift/application_container_proxy"
require "openshift/auth_service"
require "openshift/dns_service"
require "openshift/data_store"
require "openshift/exceptions"
