class Scope::Domain < Scope::Parameterized
  matches 'domain/:id/:domain_scope'
  description "Grant access to perform API actions against a single domain and the contained applications."

  DOMAIN_SCOPES = {
    :view => 'Grant read-only access to a single domain.',
    :edit => 'Grant edit access to a single domain and all its applications.',
    :admin => 'Grant full administrative access to a single domain and all its applications.',
  }.freeze

  def allows_action?(controller)
    case domain_scope
    when :view
      controller.request.method == "GET"
    else
      true
    end
  end

  def authorize_action?(permission, resource, other_resources, user)
    case domain_scope
    when :admin
      case resource
      when Domain
        resource._id === id
      when Application
        return false unless resource.domain_id === id
        Scope::Application.authorize_action?(resource._id, :admin, permission, resource, other_resources, user)
      end
    when :edit
      case resource
      when Domain
        resource._id === id && [:create_application, :create_builder_application].include?(permission)
      when Application
        return false unless resource.domain_id === id
        return true if [:destroy, :update_application].include?(permission)
        Scope::Application.authorize_action?(resource._id, :edit, permission, resource, other_resources, user)
      end
    end
  end

  def limits_access(criteria)
    case criteria.klass
    when Application then criteria = criteria.where(:domain_id => @id)
    when Domain then (criteria.options[:for_ids] ||= []) << @id
    else criteria.options[:visible] ||= false
    end
    criteria
  end

  def self.describe
    DOMAIN_SCOPES.map{ |k,v| s = with_params(nil, k); [s, v, default_expiration(s), maximum_expiration(s)] unless v.nil? }.compact
  end

  protected
    def id=(s)
      s = s.to_s
      raise Scope::Invalid, "id must be less than 40 characters" unless s.length < 40
      s = Moped::BSON::ObjectId.from_string(s)
      @id = s
    end

    def domain_scope=(s)
      raise Scope::Invalid, "'#{s}' is not a valid domain scope" unless DOMAIN_SCOPES.keys.any?{ |k| k.to_s == s.to_s }
      @domain_scope = s.to_sym
    end
end
