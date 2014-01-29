class NewCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :comp_spec, type: ComponentSpec, default: {}

  # DEPRECATED, will be removed post migration
  field :cartridge_vendor, type: String
  field :version, type: String

  def execute
    begin
      group = get_group_instance
    rescue Mongoid::Errors::DocumentNotFound
      group = GroupInstance.new(_id: group_instance_id)
    end

    if spec = comp_spec
      spec.application = application
      cartridge = spec.cartridge(pending_app_op_group)

      instance = ComponentInstance.from(cartridge, spec.name)
      instance.group_instance_id = group._id

      # write atomically
      skip_map = application.downloaded_cart_map.nil? || !cartridge.singleton?
      application.atomic_update do
        application.group_instances << group unless group.persisted?
        application.component_instances << instance
        application.downloaded_cart_map[cartridge.original_name] = CartridgeCache.cartridge_to_data(cartridge) unless skip_map
      end
    end
  end

  def rollback
    begin
      instance = get_component_instance

      application.atomic_update do
        instance.delete
        application.downloaded_cart_map.delete_if{ |_, c| c["versioned_name"] == instance.cartridge_name} if application.downloaded_cart_map
      end

      # remove the ssh key for this component, if any
      remove_ssh_keys = application.app_ssh_keys.find_by(component_id: instance._id) rescue []
      remove_ssh_keys = [remove_ssh_keys].flatten
      if remove_ssh_keys.length > 0
        keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup}
        op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
        Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pullAll" => { app_ssh_keys: keys_attrs }})
      end

      # remove the ssh keys and environment variables from the domain, if any
      application.domain.remove_system_ssh_keys(instance._id)
      application.domain.remove_env_variables(instance._id)

    rescue Mongoid::Errors::DocumentNotFound
      # ignore if component instance is already deleted
    end
  end

end
