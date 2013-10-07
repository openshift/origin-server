class RemoveGearOpGroup < PendingAppOpGroup

  field :gear_id, type: String

  def elaborate(app)
    group_instance = (app.group_instances.select { |gi| (gi.gears.select { |g| g._id.to_s == gear_id.to_s }).length > 0 }).first
    return [] if group_instance.nil?

    ops = app.calculate_gear_destroy_ops(group_instance._id.to_s, [Moped::BSON::ObjectId(gear_id.to_s)], group_instance.addtl_fs_gb)

    if app.scalable
      all_ops_ids = ops.map{ |op| op._id.to_s }
      ops.push UpdateClusterOp.new(prereq: all_ops_ids)
    end

    all_ops_ids = ops.map{ |op| op._id.to_s }
    ops.push ExecuteConnectionsOp.new(prereq: all_ops_ids)

    try_reserve_gears(0, 1, app, ops)
  end

end
