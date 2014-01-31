class AddAliasOpGroup < PendingAppOpGroup

  field :fqdn, type: String

  def elaborate(app)
    app.gears.each do |gear|
      if app.scalable
        has_web_proxy = false
        gear.component_instances.select do |ci|
          has_web_proxy = ci.get_cartridge.is_web_proxy?
          if has_web_proxy
            if gear.app_dns
              # this is the primary op to add alias to the app as well to send it to the gear on the node
              pending_ops.push AddAliasOp.new(gear_id: gear.id.to_s, fqdn: fqdn)
            else
              # this op merely sends the alias information to the gear on the node but DOES not add it to the application
              # using this op for the additional web_proxy gears ensures that we do not add the alias multiple times to the app in mongo
              pending_ops.push ResendAliasesOp.new(gear_id: gear.id.to_s, fqdns: [fqdn])
            end
          end
        end
      else
        pending_ops.push AddAliasOp.new(gear_id: gear.id.to_s, fqdn: fqdn)
      end
    end

    pending_ops.push NotifyAliasAddOp.new(fqdn: fqdn)
  end

end
