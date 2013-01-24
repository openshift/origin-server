require 'digest/md5'

class UserAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "auth_user"
  
  field :user, type: String
  field :password_hash, type: String

  def password=(p)
    auth_info = Rails.application.config.auth
    salt = auth_info[:salt]
    self.password_hash = Digest::MD5.hexdigest(Digest::MD5.hexdigest(p) + salt)
  end
end
