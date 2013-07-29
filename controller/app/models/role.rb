module Role
  def self.valid?(sym)
  end

  def self.in?(given, has)
    if i = ROLES.index(has)
      given && i >= ROLES.index(given)
    end
  end

  private
    ROLES = [:read, :control, :edit, :manage]
end