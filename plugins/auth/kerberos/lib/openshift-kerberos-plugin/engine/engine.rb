require 'stickshift-controller'
require 'rails'

module SwingShift
  class KerberosAuthServiceEngine < Rails::Engine
    paths.app.controllers      << "lib/swingshift-kerberos-plugin/app/controllers"
    paths.lib                  << "lib/swingshift-kerberos-plugin/lib"
    paths.config               << "lib/swingshift-kerberos-plugin/config"
    paths.app.models           << "lib/swingshift-kerberos-plugin/app/models"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
