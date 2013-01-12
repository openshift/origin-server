require 'rubygems'
require 'digest/md5'
require 'openshift-origin-controller'
require 'date'
require 'mongoid'

module OpenShift
  class MongoAuthService < OpenShift::AuthService

    def initialize(auth_info=nil)
      if auth_info != nil
        # no-op
      elsif defined? Rails
        auth_info = Rails.application.config.auth
      else
        raise Exception.new("Mongo configuration not provided")
      end
    
      @salt         = auth_info[:salt]
      @privkeyfile  = auth_info[:privkeyfile]
      @privkeypass  = auth_info[:privkeypass]
      @pubkeyfile   = auth_info[:pubkeyfile]
    end

    def register_user(login, password)
      accnt = UserAccount.new(user: login, password: password)
      accnt.save
    end
    
    def user_exists?(login)
      UserAccount.where(user: login).count == 1
    end
    
    def generate_broker_key(app)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")                                                                                                                                                                 
      cipher.encrypt
      cipher.key = OpenSSL::Digest::SHA512.new(@salt).digest
      cipher.iv = iv = cipher.random_iv
      token = {:app_name => app.name,
               :login => app.domain.owner.login,
               :creation_time => app.created_at}
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
        raise OpenShift::AccessDeniedException.new
      end
  
      token = JSON.parse(json_token)
      username = token['login']
      app_name = token['app_name']
      
      begin
        creation_time = Time.zone.parse(token['creation_time'])
      rescue
        raise OpenShift::AccessDeniedException.new
      end
      
      begin
        user = CloudUser.find_by(login: username)
      rescue Mongoid::Errors::DocumentNotFound
        raise OpenShift::AccessDeniedException.new
      end
      
      app = Application.find(user, app_name)
      raise OpenShift::AccessDeniedException.new if app.nil? or creation_time.to_i !=  app.created_at.to_i
      return {:username => username, :auth_method => :broker_auth}
    end
    
    def authenticate(request, login, password)
      params = request.request_parameters()
      if params['broker_auth_key'] && params['broker_auth_iv']
        validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        raise OpenShift::AccessDeniedException if login.nil? || login.empty? || password.nil? || password.empty?
        encoded_password = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + @salt)
                
        begin
          account = UserAccount.find_by(user: login, password_hash: encoded_password)
          return {:username => account.user, :auth_method => :login}          
        rescue Mongoid::Errors::DocumentNotFound
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
