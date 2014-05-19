class InitGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String
  field :platform, type: String
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false

  field :gear_size, type: String
  field :addtl_fs_gb, type: Integer

  # fields for creating component instances
  field :comp_specs, type: TypedArray[ComponentSpec], default: []

  field :pre_save, type: Boolean, default: false

  def execute
    application.atomic_update do

      # create the group instance
      group_instance =
        begin
          get_group_instance
        rescue Mongoid::Errors::DocumentNotFound
          application.group_instances << GroupInstance.new(custom_id: group_instance_id, addtl_fs_gb: addtl_fs_gb, gear_size: gear_size, custom_platform: platform)
          get_group_instance
        end

      # create the component instances, if they are not present
      sparse_carts = []
      skip_map = application.downloaded_cart_map.nil? # some apps will be unreadable by old code during the switch over
      comp_specs.compact.each do |spec|
        spec.application = self.application
        unless group_instance.has_component?(spec)
          cartridge = spec.cartridge(pending_app_op_group)

          instance = ComponentInstance.from(cartridge, spec.name)
          instance.group_instance_id = group_instance._id
          application.component_instances << instance
          application.downloaded_cart_map[instance.cartridge.original_name] = CartridgeCache.cartridge_to_data(instance.cartridge) if cartridge.singleton? && !skip_map
        end

        # check if this is a sparse cart
        sparse_carts << application.find_component_instance_for(spec)._id if spec.component.is_sparse?
      end

      # add the gear
      application.gears << Gear.new(custom_id: gear_id, group_instance: group_instance, host_singletons: host_singletons, app_dns: app_dns, sparse_carts: sparse_carts)
    end
  end

  def rollback
    get_gear.delete rescue if_not_found($!)

    # if the group_instance has no more gears, then delete it and its component instances
    if (instance = get_group_instance rescue nil) && instance.gears.blank?
      application.atomic_update do
        instance.all_component_instances.each(&:delete)
        instance.delete
      end rescue if_not_found($!)
    end

    # add an op_group to remove the ssh key created/added for this gear
    remove_ssh_keys = application.app_ssh_keys.find_by(component_id: gear_id) rescue []
    remove_ssh_keys = [remove_ssh_keys].flatten
    if remove_ssh_keys.length > 0
      keys_attrs = remove_ssh_keys.map{|k| k.as_document}
      op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
      Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pullAll" => { app_ssh_keys: keys_attrs }})
      # remove the ssh keys from the mongoid model in memory
      application.app_ssh_keys.delete_if { |k| k.component_id.to_s == gear_id }
    end
  end

end
