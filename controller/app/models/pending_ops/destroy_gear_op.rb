class DestroyGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute(skip_node_ops=false)
    result_io = ResultIO.new
    unless skip_node_ops
      gear = get_gear()
      result_io = gear.destroy_gear(true)
    end
    result_io
  end

end
