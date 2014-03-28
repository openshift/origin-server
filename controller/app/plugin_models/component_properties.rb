class ComponentProperties
  attr_accessor :cartridge_name, :component_name, :version, :cartridge_vendor

  def initialize(component)
    self.component_name   = component.component_name
    self.cartridge_name   = component.cartridge.name
    self.cartridge_vendor = component.cartridge.cartridge_vendor
    self.version          = component.cartridge.version
  end
end
