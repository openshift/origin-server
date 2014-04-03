class DeleteGearOp < PendingAppOp

  field :gear_id, type: String

  def execute
    group_instance = nil
    begin
      gear = get_gear()
      group_instance = gear.group_instance
      gear.delete
      pending_app_op_group.inc(:num_gears_destroyed, 1)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end

    begin
      # if the group_instance has no more gears, then delete it and its component instances
      if group_instance and group_instance.gears.length == 0
        group_instance.all_component_instances.each do |comp_inst|
          comp_inst.delete

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

        group_instance.delete
      end
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if the group instance is already deleted
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
