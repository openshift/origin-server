class MakeAppHaOpGroup < PendingAppOpGroup

  def elaborate(app)
    app.ha = true
    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges, nil, app.group_overrides)
    ops.unshift(SetHaOp.new)
    ops.push(RegisterRoutingDnsOp.new)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end
end
