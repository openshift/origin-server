module RestApi
  # An object which can return info about the REST API
  class Info < RestApi::Base
    self.element_name = 'api'
    allow_anonymous
    singleton

    self.format = Class.new(OpenshiftJsonFormat) do
      def decode(json)
        ActiveSupport::JSON.decode(json)
      end
    end.new

    schema do
      string :version, :status
    end
    has_many :supported_api_versions, :class_name => 'string'
    has_one :data, :class_name => 'rest_api/base/attribute_hash'

    def url
      self.class.site
    end
  end
end
