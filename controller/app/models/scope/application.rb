class Scope::Application < Scope::Parameterized
  matches 'application/:id/:app_scope'
  description "Grant access to perform API actions against a single application."

  APP_SCOPES = {
    :build => nil,
    :scale => nil,
    #:read => 'Grant read-only access to a single application.',
  }.freeze

  def allows_action?(controller)
    case app_scope
    when :scale then true #FIXME temporary
    when :build then true #FIXME temporary
    else false
    end
  end

  def self.describe
    APP_SCOPES.map{ |k,v| s = with_params(nil, k); [s, v, default_expiration(s), maximum_expiration(s)] unless v.nil? }.compact!# or super
  end

  private
    def id=(s)
      s = s.to_s
      raise Scope::Invalid, "id must be less than 40 characters" unless s.length < 40
      @id = s
    end

    def app_scope=(s)
      s = s.to_sym
      raise Scope::Invalid, "'#{s}' is not a valid application scope" unless APP_SCOPES.has_key?(s)
      @app_scope = s
    end
end
