class ScaleOpGroup < PendingAppOpGroup

  field :group_instance_id, type: Moped::BSON::ObjectId
  field :scale_by, type: Integer, default: 0

  def elaborate(app)
    changes = []
    current_group_instances = app.group_instances_with_scale
    current_group_instances.each do |ginst|
      if ginst._id.to_s == group_instance_id.to_s
        final_scale = ginst.gears.length + scale_by
        final_scale = ginst.min if final_scale < ginst.min
        final_scale = ginst.max if ((final_scale > ginst.max) && (ginst.max != -1))

        changes << {
          :from => group_instance_id.to_s, :to => group_instance_id.to_s,
          :added => [], :removed => [],
          :from_scale => {:min => ginst.min, :max => ginst.max, :current => ginst.gears.length},
          :to_scale=>{:min => ginst.min, :max => ginst.max, :current => final_scale}
        }
        break
      end
    end
    ops, add_gear_count, rm_gear_count = app.calculate_ops(changes)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

end
