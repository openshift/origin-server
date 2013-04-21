class SettingsController < ConsoleController
  include AsyncAware
  include DomainAware

  def show
    @user = current_user

    async{ @domain = begin user_default_domain; rescue ActiveResource::ResourceNotFound; end }

    async{ @keys = Key.all :as => @user }
    async{ @authorizations = Authorization.all :as => @user }

    join!(30)

    if not @domain
      flash.now[:info] = "You need to set a namespace before you can create applications"
    elsif @keys.blank?
      flash.now[:info] = "You need to set a public key before you can work with application code"
    end
  end
end