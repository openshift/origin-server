#TODO: Rename to AddCartridgesOpGroup and do a migration
class AddFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []
  #field :cartridge_ids, type: Array, default: []
  field :group_overrides, type: TypedArray[GroupOverride], default: []
  field :init_git_url, type: String
  field :user_env_vars, type: Array

  def elaborate(app)
    overrides = (app.group_overrides || []) + (group_overrides || [])
    ops, gears_added, gears_removed = app.update_requirements(app.cartridges + cartridges, overrides, init_git_url, user_env_vars)
    try_reserve_gears(gears_added, gears_removed, app, ops)
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
