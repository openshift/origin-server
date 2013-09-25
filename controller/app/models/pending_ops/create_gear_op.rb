class CreateGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute(skip_node_ops=false)
    result_io = ResultIO.new
    unless skip_node_ops
      gear = get_gear()
      result_io = gear.create_gear
      raise OpenShift::NodeException.new("Unable to create gear", result_io.exitcode, result_io) if result_io.exitcode != 0
    end
    pending_app_op_group.inc(:num_gears_created, 1)
    result_io
  end
  
  def rollback(skip_node_ops=false)
    result_io = ResultIO.new
    unless skip_node_ops
      gear = get_gear()
      result_io = gear.destroy_gear(true)
    end
    pending_app_op_group.inc(:num_gears_rolled_back, 1) if state == :completed
    result_io
  end

end
