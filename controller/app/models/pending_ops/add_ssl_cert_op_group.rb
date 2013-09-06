class AddSslCertOpGroup < PendingAppOpGroup

  field :fqdn, type: String
  field :ssl_certificate, type: String
  field :private_key, type: String
  field :pass_phrase, type: Array

  def elaborate(app)
    app.group_instances.each do |group_instance|
      if group_instance.gears.where(app_dns: true).count > 0
        gear = group_instance.gears.find_by(app_dns: true)
        #op_group.pending_ops.push PendingAppOp.new(op_type: :add_ssl_cert, args: {"group_instance_id" => group_instance.id.to_s, "gear_id" => gear.id.to_s,
        #  "fqdn" => op_group.args["fqdn"], "ssl_certificate" => op_group.args["ssl_certificate"], "private_key" => op_group.args["private_key"], "pass_phrase" => op_group.args["pass_phrase"] } )
        pending_ops.push AddSslCertOp.new(group_instance_id: group_instance.id.to_s, gear_id: gear.id.to_s, 
            fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase)
        break
      end
    end
  end

end
