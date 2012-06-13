module SshkeyAware
  extend ActiveSupport::Concern

  included do
    around_filter SshkeySessionSweeper
  end

  def sshkey_uploaded?
    @has_key = false
    if session[:has_sshkey]
      logger.debug "  Hit has_sshkey cache #{session.inspect}"
      @has_keys = session[:has_sshkey]
    else
      key = Key.first :as => current_user
      @has_keys = key ? true : false
      session[:has_sshkey] = @has_keys
    end

    @has_key
  end
end
RestApi::Base.observers << SshkeySessionSweeper
SshkeySessionSweeper.instance
