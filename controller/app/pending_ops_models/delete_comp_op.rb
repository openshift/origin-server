class DeleteCompOp < PendingAppOp

  field :comp_spec, type: ComponentSpec, default: {}

  def execute
    instance = get_component_instance

    # Atomic remove of old downloaded_cart and instance
    # if application.persisted?
    #   application.atomic_update(
    #     '$unset' => {"downloaded_cart_map.#{instance.cartridge.original_name}" => 1},
    #     '$pullAll' => {'component_instances' => {'_id' => instance._id }}
    #   )
    # else
    application.atomic_update do
      instance.delete
      application.downloaded_cart_map.delete_if{ |_, c| c["versioned_name"] == instance.cartridge_name} if application.downloaded_cart_map
    end

    # remove the ssh key for this component, if any
    remove_ssh_keys = application.app_ssh_keys.find_by(component_id: instance._id) rescue []
    remove_ssh_keys = [remove_ssh_keys].flatten
    if remove_ssh_keys.length > 0
      keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup }
      op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
      Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pullAll" => { app_ssh_keys: keys_attrs }})
    end

    # remove the ssh keys and environment variables from the domain, if any
    application.domain.remove_system_ssh_keys(instance._id)
    application.domain.remove_env_variables(instance._id)
  end

end
