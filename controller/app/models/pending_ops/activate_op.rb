class ActivateOp < PendingAppOp

  field :deployment_id, type: String

  def execute
    gear = get_gear()
    gear.activate(deployment_id)
  end

end
