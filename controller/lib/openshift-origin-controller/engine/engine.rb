require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class CloudEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-origin-controller/app/controllers"
    paths.app.models           << "lib/openshift-origin-controller/app/models"
    paths.lib                  << "lib/openshift-origin-controller/lib"
    paths.config               << "lib/openshift-origin-controller/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
