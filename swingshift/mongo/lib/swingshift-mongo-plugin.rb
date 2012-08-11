require 'mongoid'
require "swingshift-mongo-plugin/mongo_auth_service"
require "swingshift-mongo-plugin/engine"
StickShift::AuthService.provider = Swingshift::MongoAuthService

module SwingShift
end
