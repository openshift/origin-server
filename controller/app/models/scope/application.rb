class Scope::Application < Scope::Parameterized
  matches 'application/:id/:app_scope'
  description "Grant access to perform API actions against a single application."

  APP_SCOPES = {
    :view => 'Grant read-only access to a single application.',
    :scale => nil,
    :build => nil,
    :edit => 'Grant edit access to a single application.',
    :admin => 'Grant full administrative access to a single application.',
  }.freeze

  def allows_action?(controller)
    case app_scope
    when :view 
      controller.request.method == "GET"
    else 
      true
    end
  end

  def authorize_action?(permission, resource, other_resources, user)
    self.class.authorize_action?(id, app_scope, permission, resource, other_resources, user)
  end

  def limits_access(criteria)
    case criteria.klass
    when Application then (criteria.options[:for_ids] ||= []) << @id
    when Domain then (criteria.options[:for_ids] ||= []) << Application.only(:domain_id).find(@id).domain_id
    else criteria.options[:visible] ||= false
    end
    criteria
  end

  def self.describe
    APP_SCOPES.map{ |k,v| s = with_params(nil, k); [s, v, default_expiration(s), maximum_expiration(s)] unless v.nil? }.compact
  end

  def self.authorize_action?(app_id, app_scope, permission, resource, other_resources, user)
    case app_scope
    when :admin 
      resource === Application && resource._id === app_id
    when :edit 
      resource === Application && resource._id === app_id && [
          :change_state, 
          :change_cartridge_state,
          :scale_cartridge,
          :view_code_details,
          :change_gear_quota,
          :create_cartridge, 
          :destroy_cartridge,
          :create_alias,
          :update_alias,
          :ssh_to_gears,
          :destroy_alias,
          #:destroy,
          #:change_members,
        ].include?(permission)
    when :build 
      return false unless resource === Domain && :create_builder_application == permission && other_resources[0]
      params = other_resources[0]
      app = Application.find(app_id)
      framework = app.requires(true).each{ |feature| cart = CartridgeCache.find_cartridge(feature, app); break cart if cart.categories.include? 'web_framework' }
      if framework && [framework.name] == params[:cartridges] && app.domain_id === params[:domain_id]
        true
      end
    when :scale 
      resource === Application && resource._id === app_id && :scale_cartridge == permission
    end
  end

  private
    def id=(s)
      s = s.to_s
      raise Scope::Invalid, "id must be less than 40 characters" unless s.length < 40
      s = Moped::BSON::ObjectId.from_string(s)
      @id = s
    end

    def app_scope=(s)
      raise Scope::Invalid, "'#{s}' is not a valid application scope" unless APP_SCOPES.keys.any?{ |k| k.to_s == s.to_s }
      @app_scope = s.to_sym
    end
end
