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
      if Rails.application.config.serve_static_assets and not Console.config.disable_static_assets
        app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
      end
    end

    def self.require_relative(file)
      file = File.expand_path(file)
      require_dependency "#{root}/#{Pathname.new(file).relative_path_from(Rails.application.root)}"
    end
  end
end

require 'console/rails/routes'
require 'console/rails/app_redirector'
require 'console/rails/filter_hash'
