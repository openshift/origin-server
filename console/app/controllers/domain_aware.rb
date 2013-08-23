module DomainAware
  extend ActiveSupport::Concern

  included do
    around_filter DomainSessionSweeper
  end

  # trigger synchronous module load 
  [Domain, Member] if Rails.env.development?

  def domains_cache_key
    [current_user.login, :domains]
  end

  def user_domains
    @domains ||= Rails.cache.fetch(domains_cache_key, :expires_in => 5.minutes) do
      Domain.find(:all, :as => current_user)
    end
  end

  def user_writeable_domains
    user_domains.select(&:editor?)
  end

  def user_owned_domains
    user_domains.select(&:owner?)
  end

  def user_default_domain
    @domain ||= user_domains.first.tap do |d|
      raise RestApi::ResourceNotFound.new(Domain.model_name, nil) unless d.present? and d.owner?
    end
  end

  def domain_is_missing
    @domain = nil
    @domains = nil
    Rails.cache.delete(domains_cache_key)
  end
end
RestApi::Base.observers << DomainSessionSweeper
DomainSessionSweeper.instance
