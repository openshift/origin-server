class NewCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :comp_spec, type: Hash, default: {}
  field :cartridge_vendor, type: String
  field :version, type: String

  def execute
    group_instance = get_group_instance()
    if comp_spec
      comp_name = comp_spec["comp"]
      cart_name = comp_spec["cart"]
      component_instance = ComponentInstance.new(cartridge_name: cart_name, component_name: comp_name, group_instance_id: group_instance._id, cartridge_vendor: cartridge_vendor, version: version)
      application.component_instances.push(component_instance)
    end
  end

  def rollback
    begin
      component_instance = get_component_instance()
      application.component_instances.delete(component_instance)

      # remove the ssh key for this component, if any
      remove_ssh_keys = application.app_ssh_keys.find_by(component_id: component_instance._id) rescue []
      remove_ssh_keys = [remove_ssh_keys].flatten
      if remove_ssh_keys.length > 0
        keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup}
        op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, user_agent: application.user_agent)
        Application.where(_id: application._id).update_all({ "$push" => { pending_op_groups: op_group.serializable_hash_with_timestamp }, "$pullAll" => { app_ssh_keys: keys_attrs }})
      end
      
      # remove the ssh keys and environment variables from the domain, if any
      application.domain.remove_system_ssh_keys(component_instance._id)
      application.domain.remove_env_variables(component_instance._id)

      # If this was a downloaded cart, remove it from the downloaded cart map
      application.downloaded_cart_map.delete_if { |cname, c| c["versioned_name"] == comp_spec["cart"] }
      application.save!
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if component instance is already deleted
    end
  end

end
