class TeamMembersController < MembersController
  include RestModelHelper
  action_log_tag_resource :member

  def show
    id = params[:id].presence
    member = membership.members.find(id)
    return render_error(:not_found, "Could not find member #{id} for team #{membership.name}", 1) if member.nil?
    render_success(:ok, "member", get_rest_member(member), "Showing member #{id} for team #{membership.name}")
  end

  def create
    params[:role] = :view unless params[:role].presence
    super
  end

  def update
    authorize! :change_members, membership
    id = params[:id].presence
    role = params[:role].presence 
    return render_error(:unprocessable_entity, "Role required for update.", 1) if role.nil? 
    return render_error(:unprocessable_entity, "Role #{role} not supported for team members", 1) unless validate_role(role)
    member = membership.members.find(id)
    if role.to_sym == :none
      membership.remove_members(member)
    else
      membership.add_members(member.clone.clear, role.to_sym)
    end
    membership.save
    render_success(:ok, "member", get_rest_member(member), "Updated member")
  end
 
  protected
    
    def membership
      @membership ||= get_team
    end
    
    def validate_role(role)
      return false unless [:view].include? role.to_sym or role.to_sym == :none
      true
    end
    
    def validate_type(type)
      return false unless type == "user"
      true
    end
    
end
