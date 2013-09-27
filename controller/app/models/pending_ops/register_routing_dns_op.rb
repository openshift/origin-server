class RegisterRoutingDnsOp < PendingAppOp

  def execute
    self.pending_app_op_group.application.register_routing_dns
    self.pending_app_op_group.application.ha = true
    self.pending_app_op_group.application.save 
  end

end
