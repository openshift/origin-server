class TeamMembersController < MembersController
  include RestModelHelper
  action_log_tag_resource :member

  def show
    id = params[:id].presence
    member = membership.members.find(id)
    return render_error(:not_found, "Could not find member #{id} for team #{membership.name}") if member.nil?
    render_success(:ok, "member", get_rest_member(member), "Showing member #{id} for team #{membership.name}")
  end

  def create
    params[:role] = :view unless params[:role].presence
    return render_error(:unprocessable_entity, "Role #{params[:role]} not supported for team members") unless Team::TEAM_MEMBER_ROLES.include? params[:role].to_sym or params[:role].to_sym == :none 
    super
  end

  def update
    authorize! :change_members, membership
    id = params[:id].presence
    role = params[:role].presence 
    return render_error(:unprocessable_entity, "Role #{role} not supported for team members") unless Team::TEAM_MEMBER_ROLES.include? role.to_sym or role.to_sym == :none 
    member = membership.members.find(id)
    if role.to_sym == :none
      membership.remove_members(member)
    else
      membership.add_members(member, role)
    end
    membership.save
    render_success(:ok, "member", get_rest_member(member), "Updated member")
  end
   
  protected
    def membership
      @membership ||= get_team
    end
end
