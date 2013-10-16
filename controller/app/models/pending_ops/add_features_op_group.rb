class AddFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []
  field :group_overrides, type: Array, default: []
  field :init_git_url, type: String
  field :user_env_vars, type: Array

  def elaborate(app)
    final_features = app.requires + features
    existing_group_overrides = app.group_overrides || []
    existing_group_overrides.map! do |go| 
      go['gear_size'] = app.default_gear_size unless go['gear_size']
      go
    end 
    final_group_overrides = existing_group_overrides + (group_overrides || [])
    ops, add_gear_count, rm_gear_count = app.update_requirements(final_features, final_group_overrides, init_git_url, user_env_vars)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end
end
