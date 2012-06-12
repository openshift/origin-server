module SshkeyAware
  extend ActiveSupport::Concern

  included do
    around_filter SshkeySessionSweeper
  end

  def sshkey_uploaded?
    has_key = false
    if session[:has_sshkey]
      logger.debug "  Hit has_sshkey cache"
      has_key = true
    else
      key = Key.first :as => session_user
      puts "#{key.inspect}"
      has_key = key ? true : false
      session[:has_sshkey] = true if has_key
    end

    has_key
  end
end
RestApi::Base.observers << SshkeySessionSweeper
SshkeySessionSweeper.instance
