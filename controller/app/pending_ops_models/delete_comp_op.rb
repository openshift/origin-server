class DeleteCompOp < PendingAppOp

  field :comp_spec, type: Hash, default: {}

  def execute
    component_instance = get_component_instance

    application.downloaded_cart_map.delete_if{ |_, c| c["versioned_name"] == component_instance.cartridge_name}
    application.component_instances.delete(component_instance)
    application.save!

    # remove the ssh key for this component, if any
    remove_ssh_keys = application.app_ssh_keys.find_by(component_id: component_instance._id) rescue []
    remove_ssh_keys = [remove_ssh_keys].flatten
    if remove_ssh_keys.length > 0
      keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup }
      op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
      Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pullAll" => { app_ssh_keys: keys_attrs }})
    end

    # remove the ssh keys and environment variables from the domain, if any
    application.domain.remove_system_ssh_keys(component_instance._id)
    application.domain.remove_env_variables(component_instance._id)
  end

end
