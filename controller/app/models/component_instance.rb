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
  include Mongoid::Timestamps::Created
  embedded_in :application

  field :group_instance_id, type: Moped::BSON::ObjectId
  field :cartridge_id, type: Moped::BSON::ObjectId
  field :component_properties, type: Hash, default: {}
  field :component_name, type: String
  field :cartridge_name, type: String

  field :manifest_text, type: String
  field :manifest_url, type: String

  # DEPRECATED - will be removed
  field :cartridge_vendor, type: String

  def self.from(cartridge, name=nil)
    name ||= cartridge.components.first.name
    inst = new(
      cartridge_name: cartridge.name,
      # LEGACY - these will be removed in a future release
      component_name: name,
      cartridge_vendor: cartridge.cartridge_vendor,
    )
    if cartridge.singleton?
      inst._id = Moped::BSON::ObjectId.from_string(cartridge.id) if cartridge.id.present?
      inst.manifest_url = cartridge.manifest_url
      inst.manifest_text = cartridge.manifest_text
      inst.cartridge_id = inst._id
    else
      inst.cartridge_id = cartridge.id
    end
    inst.instance_variable_set(:@cartridge, cartridge)
    inst
  end

  NAME_REGEX = /\A([\w\-]+(-)([\d]+(\.[\d]+)*)+)\Z/
  def self.check_name!(name)
    if name.blank? or name !~ NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(ComponentInstance, {}, [])
    end
    name
  end

  delegate :is_plugin?, :is_embeddable?, :is_web_proxy?, :is_external?, :is_web_framework?, :has_scalable_categories?, to: :cartridge
  delegate :is_sparse?, to: :component

  def group_instance
    self.application.group_instances.find(self.group_instance_id)
  end

  def gears
    gi_gears = self.application.gears.select{ |g| g.group_instance_id == self.group_instance_id }
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

  def supports_action?(action)
    cartridge.additional_control_actions.include?(action)
  end

  def component
    @component ||= cartridge.get_component(component_name)
  end
  alias_method :get_component, :component

  def cartridge
    @cartridge ||= begin
      # WARNING: during migration, this will prefer the new cartridge over the old (which means an update of the
      # old location by old code will have no effect).
      if data = (manifest_text and attributes)
        cart = CartridgeCache.find_serialized_cartridge(data)
        cart.id = _id.to_s
        cart.created_at = created_at
        self.cartridge_id = _id
        self.cartridge_name = cart.name
        self.cartridge_vendor = cart.cartridge_vendor
        cart
      # DEPRECATED: this block will be removed when downloaded_cart_map is removed
      elsif data = (cartridge_name and application.downloaded_cart_map and
                    application.downloaded_cart_map.each_value.detect{ |c| c['versioned_name'] == cartridge_name })
        cart = CartridgeCache.cartridge_from_data(data)
        cart.id = _id.to_s
        cart.created_at = created_at
        self.cartridge_id = _id
        self.cartridge_name = cart.name
        self.cartridge_vendor = cart.cartridge_vendor
        self.manifest_text = cart.manifest_text
        self.manifest_url = cart.manifest_url
        cart
      elsif cartridge_id && (cart = CartridgeCache.find_cartridge_by_id(cartridge_id))
        self.cartridge_name = cart.name
        self.cartridge_vendor = cart.cartridge_vendor
      elsif cartridge_name && (cart = CartridgeCache.find_cartridge(cartridge_name))
        self.cartridge_id = Moped::BSON::ObjectId.from_string(cart.id) if cart.id.present?
        self.cartridge_vendor = cart.cartridge_vendor
      end
      cart or raise OpenShift::UserException.new("The cartridge #{cartridge_name} is used by the application #{self.application.name} but cannot be located.")
    end
  end
  alias_method :get_cartridge, :cartridge

  def group_overrides(&block)
    e = EnumeratorArray.new do |y|
      application.group_overrides.each do |override|
        if override && override.components.any?{ |spec| matches_spec?(spec) }
          y << override
        end
      end
    end
    return e.each(&block) if block_given?
    e
  end

  def to_component_spec
    ComponentSpec.for_instance(self, self.has_application? ? self.application : nil)
  end
  alias_method :get_cartridge, :cartridge

  def matches_spec?(spec)
    component_name == spec.name && cartridge_name == spec.cartridge_name
  end

  private
    ##
    # Return the first value in the group overrides that applies to this component for <b>key</b>
    # that is not nil.
    #
    def get_value_from_group_override(key)
      raise "Remove me"
      group_overrides.each do |override|
        match = false
        override.components.each do |spec|
          if matches_spec?(spec)
            match = true
            value = spec.send(key) if spec.respond_to?(key)
            value = override.send(key) if !is_sparse? && value.nil?
            return value unless value.nil?
          end
        end
        if match
          value = override.send(key)
          return value unless value.nil?
        end
      end
      nil
    end
end
