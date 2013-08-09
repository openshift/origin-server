module Role
  def self.for(value)
    ROLES.detect{ |s| s.to_s == value.to_s }
  end

  def self.valid?(sym)
    ROLES.include?(sym)
  end

  def self.in?(given, has)
    if i = ROLES.index(has)
      given && i >= ROLES.index(given)
    end
  end

  def self.higher_of(*args)
    ROLES[args.map{ |r| ROLES.index(r) }.compact.max]
  end

  def self.all
    ROLES
  end

  private
    ROLES = [:view, :edit, :admin].freeze
end