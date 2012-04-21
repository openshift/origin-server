require "stickshift-common"
require "swingshift-mongo-plugin/swingshift/mongo_auth_service.rb"
StickShift::AuthService.provider=Swingshift::MongoAuthService
