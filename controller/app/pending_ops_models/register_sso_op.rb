class RegisterSsoOp < PendingAppOp

  field :gear_id, type: String

  def execute
    gear = get_gear()
    OpenShift::SsoService.register_gear(gear)
  end

  def rollback
    gear = get_gear()
    OpenShift::SsoService.deregister_gear(gear)
  end

end
