class AddSslCertOpGroup < PendingAppOpGroup

  field :fqdn, type: String
  field :ssl_certificate, type: String
  field :private_key, type: String
  field :pass_phrase, type: Array

  def elaborate(app)
    app.gears.each do |gear|
      if app.scalable
        if gear.component_instances.select { |ci| ci.get_cartridge.is_web_proxy? }.present?
          pending_ops.push AddSslCertOp.new(gear_id: gear.id.to_s, fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
        end
      else
        pending_ops.push AddSslCertOp.new(gear_id: gear.id.to_s, fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
      end
    end

    pending_ops.push NotifySslCertAddOp.new(fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
  end
end
