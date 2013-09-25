class RemoveGearOpGroup < PendingAppOpGroup

  # gear_id is actually gear_uuid, rename is not done to avoid migration.
  field :gear_id, type: String

  def elaborate(app)
    group_instance = (app.group_instances.select { |gi| (gi.gears.select { |g| g.uuid.to_s == gear_id.to_s }).length > 0 }).first
    return [] if group_instance.nil?
    gear = (group_instance.gears.select { |g| g.uuid.to_s == gear_id.to_s }).first
    ops = app.calculate_gear_destroy_ops(group_instance._id.to_s, [gear._id], group_instance.addtl_fs_gb)
    all_ops_ids = ops.map{ |op| op._id.to_s }
    ops.push ExecuteConnectionsOp.new(prereq: all_ops_ids)

    try_reserve_gears(0, 1, app, ops)
  end

end
