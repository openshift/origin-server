class UserProperties
  attr_accessor :id, :login, :consumed_gears, :capabilities, :plan_id, :plan_state, :max_gears, :max_domains

  def initialize(cloud_user)
    [:id, :login, :consumed_gears, :plan_id, :plan_state].each{ |sym| self.send("#{sym}=", cloud_user.send(sym)) }

    self.capabilities = cloud_user.capabilities.serializable_hash
    self.max_gears = cloud_user.max_gears
    self.max_domains = cloud_user.max_domains
    self.capabilities.delete("max_gears")
    self.capabilities.delete("max_domains")

    if self.capabilities["max_tracked_addtl_storage_per_gear"] or self.capabilities["max_untracked_addtl_storage_per_gear"]
      tracked_storage = (self.capabilities["max_tracked_addtl_storage_per_gear"] || 0)
      untracked_storage = (self.capabilities["max_untracked_addtl_storage_per_gear"] || 0)
      self.capabilities["max_storage_per_gear"] = tracked_storage + untracked_storage
      self.capabilities.delete("max_tracked_addtl_storage_per_gear")
      self.capabilities.delete("max_untracked_addtl_storage_per_gear")
    end
  end
end
