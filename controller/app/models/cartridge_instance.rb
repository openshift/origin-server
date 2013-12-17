require 'delegate'

class CartridgeInstance < SimpleDelegator
  include ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity

  attr_accessor   :gear_size, :colocate_with, :scales_from, :scales_to, :additional_storage
  attr_accessible :gear_size, :colocate_with, :scales_from, :scales_to, :additional_storage

  attr_accessor :colocate_target

  validates_numericality_of :additional_storage, only_integer: true, allow_nil: true, greater_than: 0

  validates_numericality_of :scales_from, only_integer: true, allow_nil: true, greater_than: 0
  validates_numericality_of :scales_to,   only_integer: true, allow_nil: true

  validate :scale_range_must_be_valid
  validate :cartridge_must_be_colocated
  validate :allow_obsolete_cartridge

  #
  # Do a fast check on a set of CartridgeInstance specs
  #
  def self.check_cartridge_specifications!(specs)
    specs.each do |cart|
      ComponentInstance.check_name!(cart[:name]) if cart[:name]
      cart[:name] = String(cart[:name]).presence
      cart[:url]  = String(cart[:url]).presence
      cart
    end
  end

  #
  # Generate group overrides for this set of cartridges. Colocation is done based on cartridge
  # name and should be fully qualified.
  #
  def self.overrides_for(cartridges, app=nil)
    overrides = []
    cartridges.each do |cart|
      overrides << cart.to_group_override
      next if cart.colocate_with.nil? or cart.colocate_target

      if app && (component = app.component_instances.where(cartridge_name: cart.colocate_with).first)
        cart.colocate_target = component
        overrides << {"components" => [component.to_component_spec, cart.to_component_spec]}
      else
        group = cartridges.select do |other|
          next if cart == other
          if other.name == cart.colocate_with
            cart.colocate_target = other
            other.colocate_target = cart
          end
        end.map(&:to_component_spec)
        overrides << {"components" => group}
      end
    end
    overrides.compact!
    overrides
  end

  def initialize(cart, opts=nil)
    super(cart)
    assign_attributes(opts) if opts
  end

  def cartridge
    __getobj__
  end

  def assign_attributes(values, options = {})
    sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
      send("#{k}=", v)
    end
  end

  def to_group_override
    return nil unless scales_from.present? or scales_to.present? or additional_storage.present? or gear_size.present?

    h = {"components" => [to_component_spec]}
    h["min_gears"] = scales_from unless scales_from.nil?
    h["max_gears"] = scales_to unless scales_to.nil?
    h["additional_filesystem_gb"] = additional_storage unless additional_storage.nil?
    h["gear_size"] = gear_size unless gear_size.nil?
    h
  end

  def to_component_spec
    profs = cart.profile_for_feature(name)
    profile = (profs.is_a? Array) ? profs.first : profs
    comp = profile.components.first
    {"cart" => cart.name, "comp" => comp.name}
  end

  protected
    def scale_range_must_be_valid
      errors.add(:base, 'scales_to must be -1 or greater than or equal to scales_from') if scales_to and scales_from and scales_to != -1 and scales_from > scales_to
    end

    def cartridge_must_be_colocated
      errors.add(:colocate_with, "The specified cartridge '#{colocate_with}' for colocate_with cannot be found.") if colocate_with.present? && colocate_target.nil?
    end

    def allow_obsolete_cartridge
      if not Rails.configuration.openshift[:allow_obsolete_cartridges] and is_obsolete?
        errors.add(:base, "The cartridge '#{name}' is no longer available to be added to an application.")
      end
    end
end
