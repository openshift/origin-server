require 'rubygems'
require 'digest/md5'
require 'stickshift-controller'

module Swingshift
  class MongoAuthService < StickShift::AuthService
  
    def initialize(auth_info = nil)
      if auth_info != nil
        # no-op
      elsif defined? Rails
        auth_info = Rails.application.config.auth
      else
        raise Exception.new("Mongo DataStore service is not inilialized")
      end
    
      @replica_set  = auth_info[:mongo_replica_sets]
      @host_port    = auth_info[:mongo_host_port]
      @user         = auth_info[:mongo_user]
      @password     = auth_info[:mongo_password]
      @db           = auth_info[:mongo_db]
      @collection   = auth_info[:mongo_collection]
      @salt         = auth_info[:salt]
    end
    
    def db
      if @replica_set
        con = Mongo::ReplSetConnection.new(*@host_port << {:read => :secondary})
      else
        con = Mongo::Connection.new(@host_port[0], @host_port[1])
      end
      user_db = con.db(@db)
      user_db.authenticate(@user, @password) unless @user.nil?
      user_db
    end
    
    def register_user(login,password)
      encoded_password = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + @salt)
      db.collection(@collection).insert({"_id" => login, "user" => login, "password" => encoded_password})
    end
    
    def user_exists?(login)
      hash = db.collection(@collection).find_one({"_id" => login})
      !hash.nil?
    end
    
    def generate_broker_key(app)
      iv = Base64::encode64(app.name)
      token = Base64::encode64(app.user.login)
      [iv, token]
    end

    def validate_broker_key(iv, key)
      username = Base64::decode64(key)
      appname  = Base64::decode64(iv)
      app = Application.find( CloudUser.find(username) , appname)
      if app
        return {:username => username, :auth_method => :broker_auth}
      else
        raise StickShift::AccessDeniedException
      end
    end
    
    def authenticate(request, login, password)
      params = request.request_parameters()
      if params['broker_auth_key'] && params['broker_auth_iv']
        validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        raise StickShift::AccessDeniedException if login.nil? || login.empty? || password.nil? || password.empty?
        encoded_password = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + @salt)
        hash = db.collection(@collection).find_one({"_id" => login})
        if hash && !hash.empty? && (hash["password"] == encoded_password)
          return {:username => login, :auth_method => :login}
        else
          raise StickShift::AccessDeniedException
        end
      end
    end
    
    def login(request, params, cookies)
      if params['broker_auth_key'] && params['broker_auth_iv']
        validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        data = JSON.parse(params['json_data'])
        return authenticate(request, data['rhlogin'], params['password'])
      end
    end
  end
end
