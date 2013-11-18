class DeregisterDnsOp < PendingAppOp

  field :gear_id, type: String

  def execute
    gear = get_gear()
    gear.deregister_dns
  end

end
