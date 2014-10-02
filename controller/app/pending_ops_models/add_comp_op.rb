class AddCompOp < PendingAppOp

  field :gear_id, type: String
  field :comp_spec, type: ComponentSpec
  field :init_git_url, type: String

  def execute
    gear = get_gear
    gear.add_component(get_component_instance, init_git_url)
  end

  def rollback
    result_io = nil
    unless skip_rollback
      gear = get_gear
      # do not check for gear.removed in here
      # it is being checked inside the gear.remove_component method
      # since, in addition to a node operation, this also involves a mongo update for sparse carts
      result_io = gear.remove_component(get_component_instance)
    end

    if (comp_inst = get_component_instance rescue nil)
      # remove the ssh key for this component, if any
      remove_ssh_keys = application.app_ssh_keys.find_by(component_id: comp_inst._id) rescue []
      remove_ssh_keys = [remove_ssh_keys].flatten
      if remove_ssh_keys.length > 0
        keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup}
        op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
        Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pullAll" => { app_ssh_keys: keys_attrs }})
      end

      # remove the ssh keys and environment variables from the domain, if any
      application.domain.remove_system_ssh_keys(comp_inst._id)
      application.domain.remove_env_variables(comp_inst._id)
    end

    result_io
  end

end
