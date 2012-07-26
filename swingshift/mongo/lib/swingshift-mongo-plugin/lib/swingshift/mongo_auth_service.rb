require 'rubygems'
require 'digest/md5'
require 'stickshift-controller'
require 'date'

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
      @privkeyfile  = auth_info[:privkeyfile]
      @privkeypass  = auth_info[:privkeypass]
      @pubkeyfile   = auth_info[:pubkeyfile]
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
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")                                                                                                                                                                 
      cipher.encrypt
      cipher.key = OpenSSL::Digest::SHA512.new(@salt).digest
      cipher.iv = iv = cipher.random_iv
      token = {:app_name => app.name,
               :login => app.user.login,
               :creation_time => app.creation_time}
      encrypted_token = cipher.update(token.to_json)
      encrypted_token << cipher.final
      
      public_key = OpenSSL::PKey::RSA.new(File.read(@pubkeyfile), @privkeypass)
      encrypted_iv = public_key.public_encrypt(iv)
      
      # Base64 encode the iv and token
      encoded_iv = Base64::encode64(encrypted_iv)
      encoded_token = Base64::encode64(encrypted_token)
       
      [encoded_iv, encoded_token]
    end

    def validate_broker_key(iv, key)
      key = key.gsub(" ", "+")
      iv = iv.gsub(" ", "+")
      begin
        encrypted_token = Base64::decode64(key)
        cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        cipher.decrypt
        cipher.key = OpenSSL::Digest::SHA512.new(@salt).digest
        private_key = OpenSSL::PKey::RSA.new(File.read(@privkeyfile), @privkeypass)
        cipher.iv =  private_key.private_decrypt(Base64::decode64(iv))
        json_token = cipher.update(encrypted_token)
        json_token << cipher.final
      rescue => e
        Rails.logger.debug "Broker key authentication failed. #{e.backtrace.inspect}"
        raise StickShift::AccessDeniedException.new
      end
  
      token = JSON.parse(json_token)
      username = token['login']
      app_name = token['app_name']
      creation_time = token['creation_time']
            
      user = CloudUser.find(username)
      raise StickShift::AccessDeniedException.new if user.nil?
      app = Application.find(user, app_name)
      
      raise StickShift::AccessDeniedException.new if app.nil? or creation_time != app.creation_time
      return {:username => username, :auth_method => :broker_auth}
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
