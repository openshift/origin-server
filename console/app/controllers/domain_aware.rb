module DomainAware
  extend ActiveSupport::Concern

  included do
    around_filter DomainSessionSweeper
  end

  # trigger synchronous module load
  [Domain, Member] if Rails.env.development?

  def domains_cache_key
    # Put something in the session so that logging out and back in will give a different cache key
    session_key_component = (session[:domain_cache_key_component] ||= Time.new.to_f.to_s)
    [current_user.login, session_key_component, :domains]
  end

  def user_domains(opts={})
    key = domains_cache_key
    Rails.cache.delete(key) if opts and (opts[:refresh] or opts[:clear])
    @domains ||= Rails.cache.fetch(key, :expires_in => 5.minutes) do
      Domain.find(:all, :as => current_user, :params => {:include => :application_info})
    end
  end

  def user_writeable_domains(opts={})
    user_domains(opts).select(&:editor?)
  end

  def user_owned_domains(opts={})
    user_domains(opts).select(&:owner?)
  end

  def user_default_domain(opts={})
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
