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
  field :cartridge_vendor, type: String, default: ""
  field :version, type: String, default: ""
  field :component_properties, type: Hash, default: {}
  field :group_instance_id, type: Moped::BSON::ObjectId

  NAME_REGEX = /\A([\w\-]+(-)([\d]+(\.[\d]+)*)+)\Z/
  def self.check_name!(name)
    if name.blank? or name !~ NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(ComponentInstance, {}, [])
    end
    name
  end

  delegate :is_plugin?, :is_embeddable?, :is_web_proxy?, :is_web_framework?, to: :cartridge

  def is_sparse?
    get_component.is_sparse?
  end

  def min
    min = get_group_overriding_value('min_gears')
    return (min.nil? ? get_component.scaling.min : min)
  end

  def get_group_overriding_value(key)
    self.application.group_overrides.each { |go|
      go['components'].each { |comp_spec|
        if comp_spec['cart']==self.cartridge_name and comp_spec['comp']==self.component_name
          if comp_spec.has_key?(key)
            return comp_spec[key] 
          elsif not is_sparse?
            return go[key]
          end
        end
      }
    }
    return nil
  end

  def multiplier
    mul = get_group_overriding_value('multiplier')
    return (mul.nil? ? get_component.scaling.multiplier : mul)
  end

  def max
    max = get_group_overriding_value('max_gears')
    return (max.nil? ? get_component.scaling.max : max)
  end

  def get_additional_control_actions
    cart = CartridgeCache.find_cartridge(cartridge_name, self.application)
    cart.additional_control_actions
  end

  def group_instance
    self.application.group_instances.find(self.group_instance_id)
  end

  def gears
    gi_gears = self.application.gears.select {|g| g.group_instance_id == self.group_instance_id}
    return [] unless gi_gears.present?
    ci_gears = []
    unless self.is_sparse?
      ci_gears = gi_gears
    else
      gi_gears.each do |gear|
        ci_gears << gear if (gear.host_singletons or gear.sparse_carts.include? self._id)
      end
    end
    ci_gears
  end

  # Helper method called by {Application#process_commands} to process component hook output and extract the component_properties
  def process_properties(result_io)
    unless result_io.properties["component-properties"].nil?
      result_io.properties["component-properties"].each do |gear_id, properties|
        self.component_properties = self.component_properties.merge properties
      end
      self.save!
    end
  end

  def get_feature
    cart = cartridge
    prof = get_profile
    (prof.provides.length > 0 && prof.name != cart.default_profile) ? prof.provides.first : cart.provides.first
  end

  def get_profile
    cartridge.get_profile_for_component self.component_name
  end

  def get_component
    cartridge.get_component(component_name)
  end

  def cartridge
    @cartridge ||= CartridgeCache.find_cartridge(cartridge_name, self.application) or
      raise OpenShift::UserException.new("The cartridge #{cartridge_name} is referenced in the application #{self.application.name} but cannot be located.")
  end
  alias_method :get_cartridge, :cartridge

  # @return [Hash] a simplified hash representing this {ComponentInstance} object which is used by {Application#compute_diffs}
  def to_hash
    {"cart" => cartridge_name, "comp" => component_name}
  end
  alias_method :to_component_spec, :to_hash
end
