class DestroyGearOp < PendingAppOp

  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()

    begin
      result_io = gear.destroy_gear(true) unless gear.removed
    ensure
      # setting the rollback_blocked flag to true since after this point, the operation is not reversible
      # even in case of failure, once a call is made to the node, there is no saying what damage has been done already
      self.pending_app_op_group.set :rollback_blocked, true
    end

    result_io
  end

end
