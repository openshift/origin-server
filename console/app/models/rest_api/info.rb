module RestApi
  # An object which can return info about the REST API
  class Info < RestApi::Base
    include RestApi::Cacheable

    self.element_name = 'api'
    allow_anonymous
    singleton

    self.format = Class.new(OpenshiftJsonFormat) do
      def decode(json)
        ActiveSupport::JSON.decode(json)
      end
      def mime_type
        "application/json;version=#{RestApi::API_VERSION}"
      end
    end.new

    schema do
      string :version, :status
    end
    has_many :supported_api_versions, :class_name => String
    has_one :data, :class_name => as_indifferent_hash

    def url
      self.class.site
    end
    def link(name)
      URI.parse(data[name]['href']) if data[name]
    end
    def required_params(name)
      data[name]['required_params'] if data[name]
    end

    def scopes
      @scopes ||= begin
        scopes = data['ADD_AUTHORIZATION']['optional_params'].find{ |s| s['name'] == 'scope' }
        descriptions = scopes['description'].scan(/(?!\n)\*(.*?)\n(.*?)(?:\n|\Z)/m).inject({}) do |h, (a, b)|
          h[a.strip] = b.strip if a.present? && b.present?
          h
        end
        scopes['valid_options'].map do |s|
          h = {:id => s}
          if s =~ /\:\w+/
            h[:name] = s
            h[:parameterized] = true
            h[:match] = Regexp.new(s.split(/\:\w+/).map{|t| Regexp.quote(t)}.join('\w+'))
          else
            h[:name] = s.titleize
          end
          h[:default] = true if s == scopes['default_value']
          h[:description] = descriptions[s]
          h
        end
      rescue => e
        Rails.logger.error "#{e.message} (#{e.class})\n  #{e.backtrace.join("\n  ")}"
        []
      end
    end

    cache_find_method :one
  end
end
