class RemoveAliasOpGroup < PendingAppOpGroup

  field :fqdn, type: String

  def elaborate(app)
    app.group_instances.each do |group_instance|
      if group_instance.gears.where(app_dns: true).count > 0
        gear = group_instance.gears.find_by(app_dns: true)
        #op_group.pending_ops.push PendingAppOp.new(op_type: :remove_alias, args: {"group_instance_id" => group_instance.id.to_s, "gear_id" => gear.id.to_s, "fqdn" => op_group.args["fqdn"]} )
        pending_ops.push RemoveAliasOp.new(group_instance_id: group_instance.id.to_s, gear_id: gear.id.to_s, fqdn: fqdn)
        break
      end
    end
    pending_ops.push NotifyAliasRemoveOp.new(fqdn: fqdn)
  end

end
