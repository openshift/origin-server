class DeregisterRoutingDnsOp < PendingAppOp

  def execute
    self.application.deregister_routing_dns
  end
end
