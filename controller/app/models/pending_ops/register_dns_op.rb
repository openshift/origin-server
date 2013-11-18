class RegisterDnsOp < PendingAppOp

  field :gear_id, type: String

  def execute
    begin
      gear = get_gear()
      gear.register_dns
    rescue OpenShift::DNSLoginException => e
      self.set_state(:rolledback)
      raise
    end
  end

  def rollback
    gear = get_gear()
    gear.deregister_dns
  end

end
