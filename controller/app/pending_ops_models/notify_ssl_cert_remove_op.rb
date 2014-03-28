class NotifySslCertRemoveOp < PendingAppOp

  field :fqdn, type: String

  def execute
    OpenShift::RoutingService.notify_ssl_cert_remove application,fqdn
  end

end
