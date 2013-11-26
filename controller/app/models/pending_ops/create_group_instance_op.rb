class CreateGroupInstanceOp < PendingAppOp

  # fields for creating group instance
  field :group_instance_id, type: String
  field :pre_save, type: Boolean, default: false

  # fields for creating gears
  field :gear_ids, type: Array
  field :deploy_gear_id, type: String
  field :hosts_app_dns, type: Boolean, default: false

  # fields for creating component instances
  field :comp_specs, type: Array, default: []

  def execute
    group_instance = GroupInstance.new(custom_id: group_instance_id)
    application.group_instances.push(group_instance)
    
    # create all the gears within the group instance
    gear_ids.each do |gear_id|
      host_singletons = (gear_id == deploy_gear_id)
      app_dns = (host_singletons && hosts_app_dns)
      gear = Gear.new(custom_id: gear_id, group_instance: group_instance, 
                      host_singletons: host_singletons, app_dns: app_dns)
      application.gears.push(gear)
    end

    # create the component instances
    comp_specs.each do |comp_spec|
      if comp_spec
        comp_name = comp_spec["comp"]
        cart_name = comp_spec["cart"]
        cartridge = CartridgeCache.find_cartridge(cart_name, application)
        component_instance = ComponentInstance.new(cartridge_name: cart_name, component_name: comp_name, 
                                                   group_instance_id: group_instance._id, 
                                                   cartridge_vendor: cartridge.cartridge_vendor, 
                                                   version: cartridge.version)
        application.component_instances.push(component_instance)
      end
    end
  end

  def rollback
    begin
      group_instance = get_group_instance()

      # delete all the gears within the group instance
      group_instance.gears.each do |gear|
        gear.delete
      end

      # delete all the component instances within the group instance
      group_instance.all_component_instances.each do |comp_inst|
        comp_inst.delete
      end

      group_instance.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
