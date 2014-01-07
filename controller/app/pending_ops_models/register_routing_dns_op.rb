class RegisterRoutingDnsOp < PendingAppOp

  def execute
    self.application.register_routing_dns
    self.application.ha = true
    self.application.save! 
  end

end
