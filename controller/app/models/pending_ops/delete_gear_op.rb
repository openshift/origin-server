class DeleteGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute
    begin
      gear = get_gear()
      gear.delete
      pending_app_op_group.inc(:num_gears_destroyed, 1)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end
  end

end
