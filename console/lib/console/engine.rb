require 'rails/engine'

# Engines must explicitly require dependencies
require 'barista'
require 'sass'
require 'formtastic'

module Console
  class Engine < Rails::Engine
    #FIXME: Remove in Rails 3.1+
    initializer "console.include_helpers" do |app|
      ActiveSupport.on_load(:action_controller) do
        config.helpers_path += Console::Engine.config.paths.app.helpers.to_a
      end
    end
  end
end
