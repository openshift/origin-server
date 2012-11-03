module OpenShift
  module MongoAuthServiceModule
    require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/mongo_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::MongoAuthService
