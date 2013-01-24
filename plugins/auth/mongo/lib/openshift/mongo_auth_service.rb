require 'rubygems'
require 'openshift-origin-controller'
require 'date'

module OpenShift
  class MongoAuthService < OpenShift::AuthService
  
    def initialize(auth_info = nil)
      super

      if @auth_info != nil
        # no-op
      elsif defined? Rails
        @auth_info = Rails.application.config.auth
      else
        raise Exception.new("Mongo DataStore service is not initialized")
      end
    
      @replica_set  = @auth_info[:mongo_replica_sets]
      @host_port    = @auth_info[:mongo_host_port]
      @user         = @auth_info[:mongo_user]
      @password     = @auth_info[:mongo_password]
      @db           = @auth_info[:mongo_db]
      @collection   = @auth_info[:mongo_collection]
      @ssl          = @auth_info[:ssl]
    end
    
    def db
      if @replica_set
        con = Mongo::ReplSetConnection.new(*@host_port.dup << {:read => :secondary, :ssl => @ssl})
      else
        con = Mongo::Connection.new(@host_port[0], @host_port[1], :ssl => @ssl)
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
    
    def authenticate(request, login, password)
      if request.headers['User-Agent'] == "OpenShift"
        # password == iv, login == key
        return validate_broker_key(password, login)
      else
        raise OpenShift::AccessDeniedException if login.nil? || login.empty? || password.nil? || password.empty?
        encoded_password = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + @salt)
        hash = db.collection(@collection).find_one({"_id" => login})
        if hash && !hash.empty? && (hash["password"] == encoded_password)
          return {:username => login, :auth_method => :login}
        else
          raise OpenShift::AccessDeniedException
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
