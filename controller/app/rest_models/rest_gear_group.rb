class RestGearGroup < OpenShift::Model
  attr_accessor :uuid, :name, :gear_profile, :cartridges, :gears, :scales_from, :scales_to, :base_gear_storage, :additional_gear_storage

  def initialize(group_instance, gear_states = {}, url, nolinks)
    self.uuid         = group_instance._id.to_s
    self.name         = self.uuid
    self.gear_profile = group_instance.gear_size
    self.gears        = group_instance.gears.map{ |gear| 
      { :id => gear.uuid, 
        :state => gear_states[gear.uuid] || 'unknown', 
      } 
    }
    
    self.cartridges   = group_instance.all_component_instances.map { |component_instance| 
      cart = CartridgeCache.find_cartridge(component_instance.cartridge_name)
      component_instance.component_properties.merge({
        :name => cart.name, 
        :display_name => cart.display_name,
        :tags => cart.categories
      }) 
    }
    
    self.scales_from    = group_instance.min
    self.scales_to    = group_instance.max
    self.base_gear_storage = Gear.base_filesystem_gb(self.gear_profile)
    self.additional_gear_storage = group_instance.addtl_fs_gb
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
