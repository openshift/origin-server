class NotifyAliasAddOp < PendingAppOp

  field :fqdn, type: String

  def execute
    OpenShift::RoutingService.notify_add_alias application,fqdn
  end

  def rollback
    OpenShift::RoutingService.notify_remove_alias application,fqdn
  end

end
