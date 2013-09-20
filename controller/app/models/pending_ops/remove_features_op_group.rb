class RemoveFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []
  field :group_overrides, type: Array, default: []
  field :remove_all_features, type: Boolean, default: false

  def elaborate(app)
    final_features = []
    final_features = app.requires - features unless remove_all_features
    final_group_overrides = (app.group_overrides || []) + (group_overrides || [])
    ops, add_gear_count, rm_gear_count = app.update_requirements(final_features, final_group_overrides)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end
end
