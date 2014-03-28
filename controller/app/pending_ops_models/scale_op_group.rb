class ScaleOpGroup < PendingAppOpGroup

  field :group_instance_id, type: Moped::BSON::ObjectId
  field :scale_by, type: Integer, default: 0

  def elaborate(app)
    changes = []
    overrides = app.group_instances_with_overrides
    if override = overrides.find{ |o| o.instance._id === group_instance_id }
      exact = override.instance.gears.length + scale_by
      from = override
      to = GroupOverride.new(nil, exact, exact).merge(override)
      changes << GroupChange.new(from, to)
    end

    ops, gears_added, gears_removed = app.calculate_ops(changes, [], nil, app.group_overrides)
    try_reserve_gears(gears_added, gears_removed, app, ops)
  end

end
