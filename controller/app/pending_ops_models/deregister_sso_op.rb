class DeregisterSsoOp < PendingAppOp

  field :gear_id, type: String

  def execute
    gear = get_gear()
    OpenShift::SsoService.deregister_gear(gear)
  end

end
