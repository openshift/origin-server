module Account
  module Dashboard
    extend ActiveSupport::Concern
    include DomainAware

    def show
      @user = current_user
      @user.load_email_address
      @identities = Identity.find @user
      @show_email = @identities.any? {|i| i.id != i.email }

      user_default_domain rescue nil

      @keys = Key.find :all, :as => @user

      render :layout => 'console'
    end
  end
end

