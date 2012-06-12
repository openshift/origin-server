module DomainAware
  extend ActiveSupport::Concern

  included do
    around_filter DomainSessionSweeper
  end

  def user_default_domain
    @domain ||= begin
      if name = session[:domain]
        logger.debug "  Using cached domain #{name}"
        Domain.new({:id => name, :as => current_user}, true)
      else
        Domain.find(:one, :as => current_user).tap do |domain|
          session[:domain] = domain.id
        end
      end
    end
  end
end
RestApi::Base.observers << DomainSessionSweeper
DomainSessionSweeper.instance
