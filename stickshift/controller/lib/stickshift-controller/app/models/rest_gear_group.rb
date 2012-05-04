class RestGearGroup < StickShift::Model
  attr_accessor :name, :cartridge, :gears

  def initialize(group_instance)
    app             = group_instance.app
    self.name       = group_instance.name
    self.gears      = group_instance.gears.map{ |gear| {:id => gear.uuid} }
    self.cartridge = group_instance.component_instances.map{ |comp_inst| {:name => app.comp_instance_map[comp_inst].parent_cart_name}}
    self.cartridge.delete_if{ |comp| comp[:name] == app.name }
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
