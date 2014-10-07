
class DisableAppHaOpGroup < PendingAppOpGroup

  def elaborate(app)
    app.ha = false
    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges, nil, app.group_overrides)
    ops.unshift(UnsetHaOp.new)
    ops.push(DeregisterRoutingDnsOp.new) if Rails.configuration.openshift[:manage_ha_dns]
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end
end
