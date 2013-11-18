class DeleteGearOp < PendingAppOp

  field :gear_id, type: String

  def execute
    begin
      gear = get_gear()
      group_instance = gear.group_instance
      gear.delete
      pending_app_op_group.inc(:num_gears_destroyed, 1)
      
      # if the group_instance has no more gears, then delete it
      group_instance.delete if group_instance.gears.length == 0
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear or group_instance is already deleted
    end
  end

end
