require 'rubygems'
require 'digest/md5'
require 'stickshift-controller'
require 'date'

module Swingshift
  class RemoteUserAuthService < StickShift::AuthService

    def initialize(auth_info = nil)
      # This is useful for testing
      if auth_info.nil?
        auth_info = Rails.application.config.auth
      end

      @trusted_header = auth_info[:trusted_header]
      @salt           = auth_info[:salt]
      @privkeyfile    = auth_info[:privkeyfile]
      @privkeypass    = auth_info[:privkeypass]
      @pubkeyfile     = auth_info[:pubkeyfile]
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

    # The base_controller will actually pass in a password but it can't be
    # trusted.  REMOTE_USER must only be set if the web server has verified the
    # password.
    def authenticate(request, login=nil, password=nil)
      params = request.request_parameters()
      if params['broker_auth_key'] && params['broker_auth_iv']
        return validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        authenticated_user = request.env[@trusted_header]
        raise StickShift::AccessDeniedException if authenticated_user.nil?
        return {:username => authenticated_user, :auth_method => :login}
      end
    end

    # This is only called by the legacy controller and should be removed as
    # soon as all clients have been ported.
    def login(request, params, cookies)
      if params['broker_auth_key'] && params['broker_auth_iv']
        return validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        username = request.env[@trusted_header]
        Rails.logger.debug("Found" + username)
        return authenticate(request, username)
      end
    end
  end
end
