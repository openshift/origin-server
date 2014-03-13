class TeamsController < BaseController
  include RestModelHelper
  action_log_tag_resource :team

  def index
    rest_teams = Team.accessible(current_user).map {|t| get_rest_team(t)}
    render_success(:ok, "teams", rest_teams, "Listing teams for user #{@cloud_user.login}")
  end

  def show
    id = params[:id].presence
    team = get_team(id)
    render_success(:ok, "team", get_rest_team(team), "Showing team #{id} for user #{@cloud_user.login}")
  end


  def create
    authorize! :create_team, current_user
    name = params[:name].presence
    
    return render_error(:forbidden, "Reached team limit of #{@cloud_user.max_teams}", 193) if Team.where(owner_id: @cloud_user._id).length >= @cloud_user.max_teams
       
    team = Team.new(name: name, owner_id: @cloud_user._id)
    if team.valid?
      team.save_with_duplicate_check! 
    else
      messages = get_error_messages(team)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end
    render_success(:created, "team", get_rest_team(team), "Added #{team.name}")
  end

  def update
    id = params[:id].presence
    name = params[:name].presence
    team = get_team(id)
    authorize! :update, team
    
    team.name = name unless name.nil? 
    if team.valid?
      team.save_with_duplicate_check! 
    else
      messages = get_error_messages(team)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end
    render_success(:ok, "team", get_rest_team(team), "Updated team")
  end
  
  def destroy
    id = params[:id].presence
    team = get_team(id)
    authorize! :destroy, team
    team.destroy_team
    render_success(:ok, nil, nil, "Deleted team #{id}")
  end
end
