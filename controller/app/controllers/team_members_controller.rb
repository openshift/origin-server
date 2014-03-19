class TeamMembersController < MembersController
  include RestModelHelper
  action_log_tag_resource :member
  
  def create
    return render_error(:unprocessable_entity, "You cannot modify a teams that maps to an external group via the API.", 1) unless membership.maps_to.nil?
    super
  end
  
  def update
    return render_error(:unprocessable_entity, "You cannot modify a teams that maps to an external group via the API.", 1) unless membership.maps_to.nil?
    super
  end
  
  def leave
    return render_error(:unprocessable_entity, "You cannot leave a global team.", 1) unless membership.maps_to.nil?
    super
  end
  
  def destroy
    return render_error(:unprocessable_entity, "You cannot modify a teams that maps to an external group via the API.", 1) unless membership.maps_to.nil?
    super
  end

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
