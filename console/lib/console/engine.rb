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
    raise "Code needs changes for rails != 3.0" if Rails.version[0..3] != '3.0.'
    initializer "console.include_helpers" do |app|
      ActiveSupport.on_load(:action_controller) do
        if Console.config.include_helpers
          puts "config.helpers_path BEFORE #{config.helpers_path.inspect}"
          config.helpers_path += Console::Engine.config.paths.app.helpers.to_a
          puts "config.helpers_path AFTER  #{config.helpers_path.inspect}"
        end
      end
    end
    initializer "console.static_assets" do |app|
      # Goes before Rack::Lock but after an application's own static assets
      app.middleware.insert_after 'ActionDispatch::Static', ::ActionDispatch::Static, "#{root}/public"
    end
  end
end

require 'console/rails/routes'
require 'console/rails/app_redirector'
require 'console/rails/filter_hash'
