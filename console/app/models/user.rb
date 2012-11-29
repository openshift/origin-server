#
# The REST API model object representing the currently authenticated user.
#
class User < RestApi::Base
  singleton

  schema do
    string :login, :plan_id
    integer :max_gears, :consumed_gears
  end

  has_many :keys
  has_many :domains

  def plan_id
    super or 'freeshift'
  end

  def plan
    @plan ||= Aria::MasterPlan.cached.find plan_id
  end
  def plan=(plan)
    @plan_id = plan.is_a?(String) ? plan : plan.id
  end

  include Capabilities
  def to_capabilities
    Capabilities::Cacheable.from(self.capabilities.merge :max_gears => max_gears, :consumed_gears => consumed_gears || 0)
  end
  def gear_sizes
    Array(capabilities[:gear_sizes]).map(&:to_sym)
  end

  def can_modify_storage?
    max_storage_per_gear > 0
  end
end
