#TODO: Rename to AddCartridgesOpGroup and do a migration
class AddFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []  # DEPRECATED: migrated out of use
  field :cartridges, type: Array #<Hash>     # May be nil on unmigrated apps
  field :group_overrides, type: TypedArray[GroupOverride]
  field :init_git_url, type: String
  field :user_env_vars, type: Array
  field :region_id, type: Moped::BSON::ObjectId 

  def elaborate(app)
    # use the newer versions of a cartridge
    carts = {}
    cartridges.each{ |c| carts[c.name] = c unless carts.has_key?(c.name) }
    app.cartridges.each{ |c| carts[c.name] = c unless carts.has_key?(c.name) }

    overrides = (app.group_overrides || []) + (group_overrides || [])
    ops, gears_added, gears_removed = app.update_requirements(carts.values, nil, overrides, init_git_url, user_env_vars, region_id)
    try_reserve_gears(gears_added, gears_removed, app, ops)
  end

  def execute_rollback(result_io=nil)
    super(result_io)

    # if a rollback was triggered and was successful,
    # and if the app no longer has group_instances or component_instances,
    # then delete this application
    if self.application.group_instances.blank? and self.application.component_instances.blank?
      self.application.delete
      self.application.pending_op_groups.clear
    end
  end

  def cartridges
    @cartridges ||= begin
      if attributes['cartridges'].presence
        CartridgeCache.find_serialized_cartridges(attributes['cartridges'])
      elsif features.presence
        CartridgeCache.find_cartridges(features.presence)
      else
        []
      end
    end
  end
end
