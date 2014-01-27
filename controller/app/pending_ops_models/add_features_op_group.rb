#TODO: Rename to AddCartridgesOpGroup and do a migration
class AddFeaturesOpGroup < PendingAppOpGroup

  field :features, type: Array, default: []  # DEPRECATED: migrated out of use
  field :cartridges, type: Array #<Hash>     # May be nil on unmigrated apps
  field :group_overrides, type: TypedArray[GroupOverride]
  field :init_git_url, type: String
  field :user_env_vars, type: Array

  def elaborate(app)
    # use the newer versions of a cartridge
    carts = {}
    cartridges.each{ |c| carts[c.name] = c unless carts.has_key?(c.name) }
    app.cartridges.each{ |c| carts[c.name] = c unless carts.has_key?(c.name) }

    overrides = (app.group_overrides || []) + (group_overrides || [])
    ops, gears_added, gears_removed = app.update_requirements(carts.values, nil, overrides, init_git_url, user_env_vars)
    try_reserve_gears(gears_added, gears_removed, app, ops)
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
