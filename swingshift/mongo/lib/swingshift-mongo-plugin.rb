module Swingshift
  module AuthService
    require 'swingshift-mongo-plugin/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "swingshift-mongo-plugin/lib/swingshift/mongo_auth_service.rb"
StickShift::AuthService.provider=Swingshift::MongoAuthService
