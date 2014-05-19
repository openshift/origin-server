module OpenShift
  module GearPlacementModule
    require 'gear_placement_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/gear_placement_plugin.rb"
