#
# This is a programmatic scope applied to ci_builders
#
class Scope::DomainBuilder < Scope::Parameterized
  matches 'domain/:id/builder'
  description "Grant access to build applications in a domain."

  def initialize(app)
    self.id = app.domain_id
    self.app = app
  end

  def allows_action?(controller)
    true
  end

  def authorize_action?(permission, resource, other_resources, user)
    case resource
    when Domain
      if :create_builder_application == permission && other_resources[0]
        params = other_resources[0]
        (app.domain_id === params[:domain_id])
      end
    when Application
      if app.domain_id === resource.domain_id
        b = Ability.has_permission?(user, permission, Application, :admin, resource, *other_resources)
        b && resource.builder_id == builder_id
      end
    end
  end

  def limits_access(criteria)
    case criteria.klass
    when Application then
      (criteria.options[:conditions] ||= []).concat([{:domain_id => @id}])
    when Domain then (criteria.options[:for_ids] ||= []) << @id
    else criteria.options[:visible] ||= false
    end
    criteria
  end

  def self.describe
    s = with_params(nil)
    [s, scope_description, default_expiration(s), maximum_expiration(s)]
  end

  def builder_id
    app._id
  end

  private
    def id=(s)
      s = s.to_s
      raise Scope::Invalid, "id must be less than 40 characters" unless s.length < 40
      s = Moped::BSON::ObjectId.from_string(s)
      @id = s
    end

    attr_accessor :app
end
