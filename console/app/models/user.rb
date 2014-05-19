#
# The REST API model object representing the currently authenticated user.
#
class User < RestApi::Base
  singleton

  schema do
    string :id, :login, :plan_id
    integer :max_gears, :consumed_gears, :max_domains, :max_teams, :plan_quantity
    date :plan_expiration_date
  end

  has_many :keys
  has_many :domains

  has_one :usage_rates, :class_name => as_indifferent_hash

  def consumed_gears
    attributes[:consumed_gears] || 0
  end

  def max_domains
    attributes[:max_domains] || 1
  end

  def max_teams
    attributes[:max_teams] || 0
  end

  def view_global_teams
    !!capabilities[:view_global_teams]
  end

  def plan_quantity
    attributes[:plan_quantity] || 1
  end

  include Capabilities
end
