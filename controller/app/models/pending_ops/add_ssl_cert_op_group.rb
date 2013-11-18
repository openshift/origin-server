class AddSslCertOpGroup < PendingAppOpGroup

  field :fqdn, type: String
  field :ssl_certificate, type: String
  field :private_key, type: String
  field :pass_phrase, type: Array

  def elaborate(app)
    if app.gears.where(app_dns: true).count > 0
      gear = app.gears.find_by(app_dns: true)
      pending_ops.push AddSslCertOp.new(gear_id: gear.id.to_s, fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
    end
    pending_ops.push NotifySslCertAddOp.new(fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
  end

end
