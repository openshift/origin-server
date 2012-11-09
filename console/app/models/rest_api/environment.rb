module RestApi
  class Environment < RestApi::Base
    include RestApi::Cacheable
    allow_anonymous
    singleton

    schema do
      string :domain_suffix
    end

    cache_find_method :one
  end
end
