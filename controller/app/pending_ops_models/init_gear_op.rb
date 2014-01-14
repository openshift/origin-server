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
      application.group_instances.push(GroupInstance.new(custom_id: group_instance_id))
      group_instance = get_group_instance()
    end

    application.gears.push(Gear.new(custom_id: gear_id, group_instance: group_instance, host_singletons: host_singletons, app_dns: app_dns))

    # create the component instances, if they are not present
    comp_specs.each do |comp_spec|
      if comp_spec
        unless group_instance.has_component?(comp_spec)
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

    # add an op_group to remove the ssh key created/added for this gear 
    remove_ssh_keys = application.app_ssh_keys.find_by(component_id: gear_id) rescue []
    remove_ssh_keys = [remove_ssh_keys].flatten
    if remove_ssh_keys.length > 0
      keys_attrs = remove_ssh_keys.map{|k| k.serializable_hash}
      op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
      Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.serializable_hash_with_timestamp }, "$pullAll" => { app_ssh_keys: keys_attrs }})

      # remove the ssh keys from the mongoid model in memory
      application.app_ssh_keys.delete_if { |k| k.component_id.to_s == gear_id }
    end
  end

end
