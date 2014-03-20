#
# The REST API model object representing the team
#
class Team < RestApi::Base
  include Membership

  class Member < ::Member
    belongs_to :team
    self.schema = ::Member.schema
  end

  schema do
    string :id
    string :name
  end

  has_members :as => Team::Member

  singular_resource

end
