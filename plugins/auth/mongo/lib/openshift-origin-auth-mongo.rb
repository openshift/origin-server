module OpenShift
  class MongoAuthService < OpenShift::AuthService
    require 'openshift-origin-auth-mongo/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-mongo/lib/openshift/mongo_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::MongoAuthService
