module SshkeyAware
  extend ActiveSupport::Concern

  included do
    around_filter SshkeySessionSweeper
  end

  def sshkey_uploaded?
    @has_keys = false
    if !session[:has_sshkey].nil?
      logger.debug "  User has cached keys"
      @has_keys = session[:has_sshkey]
    else
      key = Key.first :as => current_user rescue nil
      @has_keys = key ? true : false
      session[:has_sshkey] = @has_keys
    end

    @has_keys
  end
  def update_sshkey_uploaded(keys)
    @has_keys = keys.present?
    session[:has_sshkey] = @has_keys
  end
end
RestApi::Base.observers << SshkeySessionSweeper
SshkeySessionSweeper.instance
