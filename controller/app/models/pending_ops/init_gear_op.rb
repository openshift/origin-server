class InitGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false

  def execute
    group_instance = nil
    
    # if the group_instance doesn't exist, create it
    begin 
      group_instance = get_group_instance()
    rescue Mongoid::Errors::DocumentNotFound
      pending_app_op_group.application.group_instances.push(GroupInstance.new(custom_id: group_instance_id))
      group_instance = get_group_instance()
    end
    
    group_instance.gears.push(Gear.new(custom_id: gear_id, group_instance: group_instance, host_singletons: host_singletons, app_dns: app_dns))
  end
  
  def rollback
    begin
      gear = get_gear()
      gear.delete
      
      # if the group_instance has no more gears, then delete it
      group_instance = get_group_instance()
      group_instance.delete if group_instance.gears.length == 0
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end
  end

end
