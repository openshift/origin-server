class RestAlias < OpenShift::Model
  attr_accessor :id, :has_private_ssl_certificate, :certificate_added_at, :links

  def initialize(app, al1as, url, nolinks=false)
    self.id = al1as.fqdn
    self.has_private_ssl_certificate = al1as["has_private_ssl_certificate"]
    self.certificate_added_at = al1as["certificate_added_at"]
    app_id = app._id
    unless nolinks
      self.links = {
        "GET" => Link.new("Get alias", "GET", URI::join(url, "application/#{app_id}/alias/#{self.id}")),
        "UPDATE" => Link.new("Update alias", "PUT", URI::join(url, "application/#{app_id}/alias/#{self.id}"),
          [Param.new("ssl_certificate", "string", "Content of SSL Certificate"), 
            Param.new("private_key", "string", "Private key for the certificate.  Required if adding a certificate")], 
            [OptionalParam.new("pass_phrase", "string", "Optional passphrase for the private key")]),
        "DELETE" => Link.new("Delete alias", "DELETE", URI::join(url, "application/#{app_id}/alias/#{self.id}"))
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "alias"
    super(options)
  end
end
