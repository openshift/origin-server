module RestApi
  class Environment < RestApi::Base
    include RestApi::Cacheable
    allow_anonymous
    singleton

    schema do
      string :domain_suffix
      boolean :external_cartridges_enabled
    end

    cache_find_method :one
  end
end
