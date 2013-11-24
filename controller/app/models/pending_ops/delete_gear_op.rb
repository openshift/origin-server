class DeleteGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute
    begin
      group_instance = get_group_instance()
      gear = get_gear()
      gear.delete
      pending_app_op_group.inc(:num_gears_destroyed, 1)
      
      # if the group_instance has no more gears, then delete it
      group_instance.delete if group_instance.gears.length == 0
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear or group_instance is already deleted
    end
  end

end
