class Scope::Session < Scope::Simple
  description "Grants a client the authority to perform all API actions against your account."

  def allows_action?(controller)
    true
  end
end
