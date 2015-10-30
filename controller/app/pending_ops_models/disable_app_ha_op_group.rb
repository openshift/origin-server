
class DisableAppHaOpGroup < PendingAppOpGroup

  def elaborate(app)
    app.ha = false
    overrides = app.group_overrides
    overrides.each do |override|
      override.components.delete_if {|c| c.class == ComponentOverrideSpec && c.name == "web_proxy" && defined? c.min_gears }
    end
    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges, nil, overrides)
    ops.unshift(UnsetHaOp.new)
    ops.push(DeregisterRoutingDnsOp.new) if Rails.configuration.openshift[:manage_ha_dns]
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end
end
