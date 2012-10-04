require 'stickshift-controller'
require 'rails'

module StickShift
  class CloudEngine < Rails::Engine
    paths.app.controllers      << "lib/stickshift-controller/app/controllers"
    paths.app.models           << "lib/stickshift-controller/app/models"
    paths.lib                  << "lib/stickshift-controller/lib"
    paths.config               << "lib/stickshift-controller/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end
