#
# The REST API model object representing the currently authenticated user.
#
class User < RestApi::Base
  singleton

  schema do
    string :login, :plan_id
  end

  include Capabilities
  has_many :keys
  has_many :domains
  has_one :consumed_gear_sizes, :class_name => 'rest_api/base/attribute_hash'

  def plan_id
    super or 'freeshift'
  end

  def plan
    @plan ||= Aria::MasterPlan.cached.find plan_id
  end
  def plan=(plan)
    @plan_id = plan.is_a?(String) ? plan : plan.id
  end

  def can_modify_storage?
    max_storage_per_gear > 0
  end

end
