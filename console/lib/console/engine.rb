require 'rails/engine'

# Engines must explicitly require dependencies
require 'barista'
require 'sass'

module Console
  class Engine < Rails::Engine
  end
end
