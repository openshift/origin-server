class DestroyGearOp < PendingAppOp

  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.destroy_gear(true) unless gear.removed
    
    # setting the rollback_blocked flag to true since after this point, the operation is not reversible
    self.pending_app_op_group.set :rollback_blocked, true
    
    result_io
  end

end
