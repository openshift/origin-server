class TeamMembersController < MembersController
  include RestModelHelper
  action_log_tag_resource :member

  protected
    
    def membership
      @membership ||= get_team
    end
    
    def allowed_roles
      [:view]
    end
    
    def allowed_member_types
      ["user"]
    end
    
end
