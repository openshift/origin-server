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
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
      puts app.config.middleware.pretty_inspect
    end
  end
end
