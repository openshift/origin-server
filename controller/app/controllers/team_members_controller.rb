class TeamMembersController < MembersController
  include RestModelHelper
  before_filter :check_global, :only => [:create, :destroy, :update, :leave]
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

    def check_global
      return render_error(:unprocessable_entity, "You cannot modify the membership of this team, because it maps to an external group.", 1) if membership.owner_id.nil?
    end

end
