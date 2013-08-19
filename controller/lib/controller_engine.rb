require 'openshift-origin-controller'
require 'rails'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/mime_types'

module Mime
  class Type
    class << self
      def lookup(string)
         LOOKUP[string.split(';').first]
       end
    end
  end
end

raise "Rails has now implemented :patch support" if Rails.version.to_f >= 4.0
# See https://github.com/rails/rails/issues/348
module ActionDispatch
  class Request < Rack::Request
    def patch?
      HTTP_METHOD_LOOKUP[request_method] == :patch
    end

    delegate :patch, :to => :request
  end

  module Routing
    self.send(:remove_const, "HTTP_METHODS")
    HTTP_METHODS = [:get, :head, :post, :put, :delete, :options, :patch]

    class Mapper
      def patch(*args, &block)
        map_method(:patch, *args, &block)
      end
    end
  end
end

class OpenShift::Responder < ::ActionController::Responder
  ACTIONS_FOR_VERBS	=	{ :post => :new, :put => :edit, :patch => :update }
  def api_behavior(error)
    raise error unless resourceful?
    status = options[:status] || (resource.respond_to?(:status) && resource.status) || nil
    display resource, status: status
  end
end

module OpenShift
  class CloudEngine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/lib"]
  end
end
