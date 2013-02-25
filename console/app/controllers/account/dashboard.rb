module Account
  module Dashboard
    extend ActiveSupport::Concern
    include DomainAware

    def show
      @user = current_user
      user_default_domain rescue nil
      @keys = Key.all :as => @user
      @authorizations = Authorization.all :as => @user
    end
  end
end

