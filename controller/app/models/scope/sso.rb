class Scope::Sso < Scope::Simple
  # Marker scope to indicate an authorization token should be destroyed on logout

  # Override description to nil to avoid displaying in API help
  def describe
    nil
  end
end
