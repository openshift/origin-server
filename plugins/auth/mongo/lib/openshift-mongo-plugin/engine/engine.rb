require 'openshift-origin-controller'
require 'rails'

module OpenShift Origin
  class MongoAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-mongo-plugin/app/controllers"
    paths.lib                  << "lib/openshift-mongo-plugin/lib"
    paths.config               << "lib/openshift-mongo-plugin/config"
    paths.app.models           << "lib/openshift-mongo-plugin/app/models"    
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end