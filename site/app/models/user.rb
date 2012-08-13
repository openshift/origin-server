#
# The REST API model object representing the currently authenticated user.
#
class User < RestApi::Base
  singleton

  schema do
    string :login, :plan_id
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
end
