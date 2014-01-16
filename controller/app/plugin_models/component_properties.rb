class ComponentProperties
  attr_accessor :cartridge_name, :component_name, :version, :cartridge_vendor

  def initialize(component)
    self.cartridge_name = component.cartridge_name
    self.component_name = component.component_name
    self.version = component.version
    self.cartridge_vendor = component.cartridge_vendor
  end
end
