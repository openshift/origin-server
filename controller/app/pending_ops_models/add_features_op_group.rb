#TODO: Rename to AddCartridgesOpGroup and do a migration
class AddFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []
  #field :cartridge_ids, type: Array, default: []
  field :group_overrides, type: Array, default: []
  field :init_git_url, type: String
  field :user_env_vars, type: Array

  def elaborate(app)
    existing_group_overrides = app.group_overrides || []
    existing_group_overrides.map! do |go| 
      go['gear_size'] = app.default_gear_size unless go['gear_size']
      go
    end
    final_group_overrides = existing_group_overrides + (group_overrides || [])
    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges + cartridges, final_group_overrides, init_git_url, user_env_vars)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

  def cartridges
    @cartridges ||= CartridgeCache.find_cartridges(features, self.application)
  end

  def execute_rollback(result_io=nil)
    super(result_io)

    # if this was a rollback for an app creation operation,
    # and if the app no longer has group_instances or component_instances,
    # then delete this application
    if self.application.group_instances.blank? and self.application.component_instances.blank?
      self.application.delete
      self.application.pending_op_groups.clear
    end
  end

end
