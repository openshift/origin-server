require "openshift-origin-common"

module OpenShift
  module Controller
    require 'openshift-origin-controller/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-controller/app/models/cloud_user"
require "openshift-origin-controller/lib/openshift/application_container_proxy"
require "openshift-origin-controller/lib/openshift/auth_service"
require "openshift-origin-controller/lib/openshift/dns_service"
require "openshift-origin-controller/lib/openshift/data_store"
require "openshift-origin-controller/lib/openshift/mongo_data_store"
