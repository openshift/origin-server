class NotifySslCertRemoveOp < PendingAppOp

  field :fqdn, type: String

  def execute
    OpenShift::RoutingService.notify_ssl_cert_remove pending_app_op_group.application,fqdn
  end

end
