require 'rails/engine'

# Engines must explicitly require dependencies
require 'sass'
require 'barista'
require 'formtastic'
require 'pp'

require 'console/configuration'

module Console
  class Engine < Rails::Engine
    #FIXME: Remove in Rails 3.1+
    initializer "console.include_helpers" do |app|
      ActiveSupport.on_load(:action_controller) do
        config.helpers_path += Console::Engine.config.paths.app.helpers.to_a
      end
    end
    initializer "console.static_assets" do |app|
      # Goes before Rack::Lock but after an application's own static assets
      app.middleware.insert_before 'Rack::Lock', ::ActionDispatch::Static, "#{root}/public"
    end
  end
end

require 'console/rails/routes'
