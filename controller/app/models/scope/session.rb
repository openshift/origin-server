class Scope::Session < Scope::Simple
  description "Grants a client the authority to perform all API actions against your account."

  def allows_action?(controller)
    true
  end

  def authorize_action?(*args)
    true
  end

  def limits_access(criteria)
    criteria.options[:visible] = true
    criteria
  end
end
