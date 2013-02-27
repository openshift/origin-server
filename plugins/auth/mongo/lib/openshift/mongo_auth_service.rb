require 'digest/md5'

module OpenShift
  class MongoAuthService

    def initialize(auth_info=nil)
      @salt = (auth_info || Rails.configuration.auth)[:salt]
    end

    def register_user(login, password)
      accnt = UserAccount.new(user: login, password: password)
      accnt.save
    end

    def user_exists?(login)
      UserAccount.where(user: login).count == 1
    end

    def authenticate(login, password)
      raise OpenShift::AccessDeniedException if login.nil? || login.empty? || password.nil? || password.empty?
      encoded_password = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + @salt)

      account = UserAccount.find_by(user: login, password_hash: encoded_password)
      {:username => account.user}
    rescue Mongoid::Errors::DocumentNotFound
      raise OpenShift::AccessDeniedException
    end
  end
end
