require 'stickshift-controller'
require 'rails'

module SwingShift
  class MongoAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/swingshift-mongo-plugin/app/controllers"
    paths.lib                  << "lib/swingshift-mongo-plugin/lib"
    paths.config               << "lib/swingshift-mongo-plugin/config"
    paths.app.models           << "lib/swingshift-mongo-plugin/app/models"    
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end