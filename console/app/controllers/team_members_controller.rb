class TeamMembersController < MembersController

  protected
    def show_edit_with_errors(members)
      @capabilities = user_capabilities
      @new_members = members.select {|m| m.attributes[:adding] }
      render :template => 'teams/show' and return
    end

    def left_path
      teams_path
    end

    def membership
      @team ||= Team.find(params[:team_id], :params => {:include => :members}, :as => current_user)
    end

    def new_member(params={})
      member = Team::Member.new(params)
      member.team = membership
      member
    end

end
