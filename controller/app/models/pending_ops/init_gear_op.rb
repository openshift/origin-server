class InitGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false

  # fields for creating component instances
  field :comp_specs, type: Array, default: []
  
  field :pre_save, type: Boolean, default: false

  def execute
    # if the group_instance doesn't exist, create it
    group_instance = nil
    begin 
      group_instance = get_group_instance()
    rescue Mongoid::Errors::DocumentNotFound
      pending_app_op_group.application.group_instances.push(GroupInstance.new(custom_id: group_instance_id))
      group_instance = get_group_instance()
    end
    
     pending_app_op_group.application.gears.push(Gear.new(custom_id: gear_id, group_instance: group_instance, host_singletons: host_singletons, app_dns: app_dns))

    # create the component instances, if they are not present
    comp_specs.each do |comp_spec|
      if comp_spec
        unless group_instance.has_component?(comp_spec)
          comp_name = comp_spec["comp"]
          cart_name = comp_spec["cart"]
          cartridge = CartridgeCache.find_cartridge(cart_name, pending_app_op_group.application)
          component_instance = ComponentInstance.new(cartridge_name: cart_name, component_name: comp_name, 
                                                     group_instance_id: group_instance._id, 
                                                     cartridge_vendor: cartridge.cartridge_vendor, 
                                                     version: cartridge.version)
          pending_app_op_group.application.component_instances.push(component_instance)
        end
      end
    end if comp_specs.present?
  end
  
  def rollback
    begin
      gear = get_gear()
      gear.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end

    begin
      # if the group_instance has no more gears, then delete it and its component instances
      group_instance = get_group_instance()
      if group_instance.gears.length == 0
        group_instance.all_component_instances.each do |comp_inst|
          comp_inst.delete
        end

        group_instance.delete
      end 
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if the group instance is already deleted
    end
  end

end
