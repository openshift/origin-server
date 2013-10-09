class NotifyAliasAddOp < PendingAppOp

  field :fqdn, type: String

  def execute
    OpenShift::RoutingService.notify_add_alias pending_app_op_group.application,fqdn
  end

end
