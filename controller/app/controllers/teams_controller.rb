class TeamsController < BaseController
  include RestModelHelper
  action_log_tag_resource :team

  def index
    search = params[:search].presence
    return render_error(:unprocessable_entity, "Search string must be at least 2 characters", 1) if search and search.length < 2
    global = params[:global].presence
    if search and global.nil?
      return render_error(:unprocessable_entity, "You must specify the global flag when searching.  Valid values are [true, false].", 1)
    end

    if search
      if get_bool(global)
        teams = Team.accessible(current_user).where(owner_id: nil, name: /.*#{Regexp.escape(search)}.*/i).sort({name: 1})
      else
        teams = Team.accessible(current_user).where(:owner_id.exists => true, :owner_id.ne => "", name: /.*#{Regexp.escape(search)}.*/i).sort({name: 1})
      end
    else
      teams =
      case params[:owner]
      when "@self" then Team.accessible(current_user).where(owner: current_user).sort({name: 1})
      when nil     then Team.accessible(current_user).with_member(current_user).sort({name: 1})
      else return render_error(:unprocessable_entity, "Only @self is supported for the 'owner' argument.", 1)
      end
    end
    rest_teams = teams.map {|t| get_rest_team(t, if_included(:members))}
    return render_success(:ok, "teams", rest_teams, "Found #{rest_teams.count} teams") if search
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

    team = Team.new(name: name, owner_id: @cloud_user._id)
    if team.valid?
      Lock.run_in_user_lock(@cloud_user) do
        return render_error(:forbidden, "Reached team limit of #{@cloud_user.max_teams}", 193) if Team.where(owner_id: @cloud_user._id).length >= @cloud_user.max_teams
        team.save_with_duplicate_check! 
      end
    else
      messages = get_error_messages(team)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end

    @analytics_tracker.track_event("team_create", team)

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

    @analytics_tracker.track_event("team_delete", team)

    render_success(:ok, nil, nil, "Deleted team #{id}")
  end
end
