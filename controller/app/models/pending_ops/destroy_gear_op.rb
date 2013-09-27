class DestroyGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute
    gear = get_gear()
    result_io = gear.destroy_gear(true)
  end

end
