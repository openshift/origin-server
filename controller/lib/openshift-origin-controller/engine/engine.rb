require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class CloudEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-controller/app/controllers"
    paths.app.models           << "lib/openshift-controller/app/models"
    paths.lib                  << "lib/openshift-controller/lib"
    paths.config               << "lib/openshift-controller/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
