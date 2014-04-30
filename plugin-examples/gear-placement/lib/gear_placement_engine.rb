require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class GearPlacementEngine < ::Rails::Engine
    config.after_initialize do
      OpenShift::ApplicationContainerProxy.node_selector_plugin = OpenShift::GearPlacementPlugin
    end
  end
end
