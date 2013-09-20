class RollbackOp < PendingAppOp

  field :deployment_id, type: String

  def execute
    gear = get_gear()
    gear.rollback(deployment_id)
  end

end
