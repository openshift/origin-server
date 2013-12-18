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
