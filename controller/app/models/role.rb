module Role
  def self.valid?(sym)
  end

  def self.role?(sym, to)
    if i = ROLES.index_of(sym)
      i > ROLES.index_of(to)
    end
  end

  private
    ROLES = [:read, :control, :edit, :manage]
end