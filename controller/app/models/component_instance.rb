# Represents a component installed on the application
# @!attribute [r] cartridge_name
#   @return [String] The name of the cartridge that provides this component
# @!attribute [r] component_name
#   @return [String] The name of the component
# @!attribute [rw] component_properties
#   @return [Hash{String=>String}] Properties exposed by the component
# @!attribute [r] group_instance_id
#   @return [Moped::BSON::ObjectId] The ID of the {GroupInstance} that hosts this component
class ComponentInstance
  include Mongoid::Document
  embedded_in :application

  field :cartridge_name, type: String
  field :component_name, type: String
  field :component_properties, type: Hash, default: {}
  field :group_instance_id, type: Moped::BSON::ObjectId

  # @return [Boolean] true if the component does not scale.
  def is_singleton?
    get_component.is_singleton?
  end

  def group_instance
    self.application.group_instances.find(self.group_instance_id)
  end

  # Helper method called by {Application#process_commands} to process component hook output and extract the component_properties
  def process_properties(result_io)
    unless result_io.properties["component-properties"].nil?
      result_io.properties["component-properties"].each do |gear_id, properties|
        self.component_properties = self.component_properties.merge properties
      end
      self.save
    end
  end

  def get_feature
    cart = get_cartridge
    prof = get_profile
    (prof.provides.length > 0 && prof.name != cart.default_profile) ? prof.provides.first : cart.provides.first
  end

  def get_profile
    cart = get_cartridge
    prof = cart.get_profile_for_component self.component_name
  end

  def get_cartridge
    CartridgeCache.find_cartridge(cartridge_name)
  end

  def get_component
    get_cartridge.get_component(component_name)
  end

  # @return [Hash] a simplified hash representing this {ComponentInstance} object which is used by {Application#compute_diffs}
  def to_hash
    {"cart" => cartridge_name, "comp" => component_name}
  end

  def complete_update_namespace(args)
    old_ns = args["old_namespace"]
    new_ns = args["new_namespace"]
    component_instance.component_properties.each do |prop_key, prop_value|
      component_instance.component_properties[prop_key] = prop_value.gsub(/-#{old_ns}.#{Rails.configuration.openshift[:domain_suffix]}/, "-#{new_ns}.#{Rails.configuration.openshift[:domain_suffix]}")
    end
  end
end
