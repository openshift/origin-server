
class NotifySslCertAddOp < PendingAppOp

  field :fqdn, type: String
  field :ssl_certificate, type: String
  field :private_key, type: String
  field :pass_phrase, type: Array

  def execute
    OpenShift::RoutingService.notify_ssl_cert_add application,fqdn,ssl_certificate,private_key,pass_phrase
  end

  def rollback
    OpenShift::RoutingService.notify_ssl_cert_remove application,fqdn
  end

end
