require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class MongoAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-origin-auth-mongo/app/controllers"
    paths.lib                  << "lib/openshift-origin-auth-mongo/lib"
    paths.config               << "lib/openshift-origin-auth-mongo/config"
    paths.app.models           << "lib/openshift-origin-auth-mongo/app/models"    
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
