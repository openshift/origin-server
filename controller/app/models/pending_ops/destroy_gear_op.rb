class DestroyGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.destroy_gear(true) unless gear.removed
    result_io
  end

end
