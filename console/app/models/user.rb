#
# The REST API model object representing the currently authenticated user.
#
class User < RestApi::Base
  singleton

  schema do
    string :id, :login, :plan_id
    integer :max_gears, :consumed_gears
  end

  has_many :keys
  has_many :domains

  def consumed_gears
    attributes[:consumed_gears] || 0
  end

  include Capabilities
end
