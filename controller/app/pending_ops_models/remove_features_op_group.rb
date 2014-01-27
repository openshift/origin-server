#TODO: Rename RemoveCartridgesOpGroup and do a migration
class RemoveFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []
  field :remove_all_features, type: Boolean, default: false

  def elaborate(app)
    carts = []
    carts = app.cartridges.delete_if{ |c| features.include?(c.name) } unless remove_all_features
    ops, add_gear_count, rm_gear_count = app.update_requirements(carts, nil, app.group_overrides.dup)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

  def execute(result_io=nil)
    super(result_io)

    if remove_all_features
      self.application.delete
      self.application.pending_op_groups.clear
    end
  end

  def removes?(cartridge)
    features.any?{ |name| name == cartridge.name }
  end

  def execute_rollback(result_io=nil)
    super(result_io)

    # if a rollback was triggered and was successful,
    # and if the app no longer has group_instances or component_instances,
    # then delete this application
    if remove_all_features and self.application.group_instances.blank? and self.application.component_instances.blank?
      self.application.delete
      self.application.pending_op_groups.clear
    end
  end

end
