class SettingsController < ConsoleController
  include AsyncAware
  include DomainAware
  include TeamAware

  def show
    @user = current_user

    @domains = user_domains(:refresh => true)
    @teams = user_teams
    
    async{ @capabilities = user_capabilities }
    async{ @keys = Key.all :as => @user }
    async{ @authorizations = Authorization.all :as => @user }

    join!(Console.config.background_request_timeout || 30)

    update_sshkey_uploaded(@keys)

    if @domains.blank?
      flash.now[:info] = "You need to set a namespace before you can create applications"
    elsif @keys.blank?
      flash.now[:info] = "You need to set a public key before you can work with application code"
    end
  end
end
