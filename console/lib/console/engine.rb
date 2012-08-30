require 'rails/engine'

# Engines must explicitly require dependencies
require 'sass'
require 'haml'
#require 'barista'
require 'formtastic'
require 'pp'

require 'console/configuration'

module Console
  class Engine < Rails::Engine
     config.before_initialize do
      Haml.init_rails(binding)
      Haml::Template.options[:format] = :html5
    end
  end
end

require 'console/rails/routes'
require 'console/rails/app_redirector'
require 'console/rails/filter_hash'
