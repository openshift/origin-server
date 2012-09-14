module UserAssociations

  def self.when_belongs_to(klass, options)
    klass.prefix = "#{RestApi::Base.prefix}user/"
  end
end
