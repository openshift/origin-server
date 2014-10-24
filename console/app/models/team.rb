#
# The REST API model object representing the team
#
class Team < RestApi::Base
  include Membership

  class Member < ::Member
    belongs_to :team
    self.schema = ::Member.schema

    def self.default_role
      'view'
    end

    def allowed_roles
      ['view']
    end

    def role_description(role=role)
      return 'Remove from team' if role.to_s == 'none'
      return 'Team member' if role.to_s == 'view'
      super
    end

  end

  schema do
    string :id
    string :name
    boolean :global
  end

  has_members :as => Team::Member

  singular_resource

  def can_delete?
    owner?
  end

  def can_edit_membership?
    owner?
  end

  def can_leave?
    me && !owner? && !global?
  end
end
