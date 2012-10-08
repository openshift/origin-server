require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class RemoteUserAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/openshift-origin-auth-remote-user/app/controllers"
    paths.lib                  << "lib/openshift-origin-auth-remote-user/lib"
    paths.config               << "lib/openshift-origin-auth-remote-user/config"
    paths.app.models           << "lib/openshift-origin-auth-remote-user/app/models"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
