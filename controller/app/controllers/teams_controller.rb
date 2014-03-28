class TeamsController < BaseController
  include RestModelHelper
  action_log_tag_resource :team

  def index
    teams =
      case params[:owner]
      when "@self" then Team.accessible(current_user).where(owner: current_user)
      when nil     then Team.accessible(current_user)
      else return render_error(:unprocessable_entity, "Only @self is supported for the 'owner' argument.", 1) 
      end
    rest_teams = teams.map {|t| get_rest_team(t, if_included(:members))}
    render_success(:ok, "teams", rest_teams, "Listing teams for user #{@cloud_user.login}")
  end

  def show
    id = params[:id].presence
    team = get_team(id)
    render_success(:ok, "team", get_rest_team(team, true), "Showing team #{id} for user #{@cloud_user.login}")
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
    render_success(:created, "team", get_rest_team(team, true), "Added #{team.name}")
  end
  # not supported
=begin
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
    render_success(:ok, "team", get_rest_team(team, true)), "Updated team")
  end
=end
  def destroy
    id = params[:id].presence
    team = get_team(id)
    authorize! :destroy, team
    team.destroy_team
    render_success(:ok, nil, nil, "Deleted team #{id}")
  end
end
