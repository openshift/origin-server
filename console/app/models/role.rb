class Role < RestApi::Base
  singular_resource
  schema do
    string :id, :name
  end

  def self.higher_of(*args)
    ROLES[args.map{ |r| ROLES.index(r.to_s) }.compact.max]
  rescue
    nil
  end

  private
    ROLES = ['view', 'edit', 'admin'].freeze
end
