require 'rails/engine'
require 'sprockets/railtie'

# Engines must explicitly require dependencies
require 'haml'
require 'formtastic'
require 'pp'

require 'console'
require 'console/configuration'

module Console
  class Engine < Rails::Engine
    config.before_initialize do
      Haml.init_rails(binding)
      Haml::Template.options[:format] = :html5
    end
    initializer "static assets" do |app|
      unless Console.config.disable_static_assets or Rails.env.production?
        app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
      end
    end
  end
end

require 'console/rails/routes'
require 'console/rails/app_redirector'
require 'console/rails/filter_hash'
