class RegisterRoutingDnsOp < PendingAppOp

  def execute
    self.application.register_routing_dns
  end
end
