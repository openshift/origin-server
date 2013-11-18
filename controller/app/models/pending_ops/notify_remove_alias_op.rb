class NotifyAliasRemoveOp < PendingAppOp

  field :fqdn, type: String

  def execute
    OpenShift::RoutingService.notify_remove_alias application,fqdn
  end

end
