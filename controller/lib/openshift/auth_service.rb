require 'digest/md5'

module OpenShift
  class AuthService
    @oo_auth_provider = OpenShift::AuthService

    def self.provider=(provider_class)
      @oo_auth_provider = provider_class
    end

    def self.instance
      @oo_auth_provider.new
    end

    def initialize(auth_info = nil)
      # This is useful for testing
      @auth_info = auth_info

      if @auth_info.nil?
        @auth_info = Rails.application.config.auth
      end

      @salt           = @auth_info[:salt]
      @privkeyfile    = @auth_info[:privkeyfile]
      @privkeypass    = @auth_info[:privkeypass]
      @pubkeyfile     = @auth_info[:pubkeyfile]

      @token_login_key = @auth_info[:token_login_key] || :login
    end

    # Be careful overriding this method in a subclass.  Doing so incorrectly
    # can break node->broker authentication when swapping plugins.
    def generate_broker_key(app)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = OpenSSL::Digest::SHA512.new(@salt).digest
      cipher.iv = iv = cipher.random_iv
      token = {:app_name => app.name,
               @token_login_key => app.domain.owner.login,
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

    # Be careful overriding this method in a subclass.  Doing so incorrectly
    # can break node->broker authentication when swapping plugins.
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
        $stderr.puts e.message
        $stderr.puts e.backtrace
        Rails.logger.debug "Broker key authentication failed. #{e.backtrace.inspect}"
        raise OpenShift::AccessDeniedException.new
      end

      token = JSON.parse(json_token)
      username = token[@token_login_key.to_s]
      app_name = token['app_name']
      creation_time = token['creation_time']

      user = CloudUser.find(login: username)
      raise OpenShift::AccessDeniedException.new if user.nil?
      app = Application.find(user, app_name)

      raise OpenShift::AccessDeniedException.new if app.nil? or creation_time != app.created_at
      return {:username => username, :auth_method => :broker_auth}
    end

    def authenticate(request, login, password)
      return {:username => login, :auth_method => :login}
    end

    def login(request, params, cookies)
      if params['broker_auth_key'] && params['broker_auth_iv']
        return {:username => params['broker_auth_key'], :auth_method => :broker_auth}
      else
        data = JSON.parse(params['json_data'])
        return {:username => data["rhlogin"], :auth_method => :login}
      end
    end
  end
end
