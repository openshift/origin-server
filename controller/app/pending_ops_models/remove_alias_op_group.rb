class RemoveAliasOpGroup < PendingAppOpGroup

  field :fqdn, type: String

  def elaborate(app)
    if app.gears.where(app_dns: true).count > 0
      gear = app.gears.find_by(app_dns: true)
      pending_ops.push RemoveAliasOp.new(gear_id: gear.id.to_s, fqdn: fqdn)
    end
    pending_ops.push NotifyAliasRemoveOp.new(fqdn: fqdn)
  end

end
