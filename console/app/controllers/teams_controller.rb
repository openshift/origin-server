class TeamsController < ConsoleController
  def index
    query_params = {}
    query_params[:include] = "members" if request.format == 'text/html'

    if params[:owner] == '@self'
      @teams = Team.find(:all, :params => query_params.merge({:owner => "@self"}), :as => current_user)
    elsif params[:search]
      if params[:search].to_s.length >= 2
        @teams = (Team.find(:all, :params => query_params.merge({:global => params[:global] == 'true', :search => params[:search]}), :as => current_user) rescue [])
      else
        @teams = []
      end
    else
      @teams = Team.find(:all, :params => query_params, :as => current_user)
    end

    respond_to do |format|
      format.json do
        render :json => @teams.map {|t| {:id => t.id, :name => t.name} }
      end

      format.html do
        @can_create = user_capabilities.max_teams > @teams.select(&:owner?).count
        render
      end
    end    
  end

  def show
    @team = Team.find(params[:id].to_s, :as => current_user)
  end

  def new
    @team = Team.new
    @referrer = valid_referrer(params[:then])
  end

  def create
    @team = Team.new params[:team]
    @team.as = current_user

    @referrer = valid_referrer(params[:then])

    if @team.save
      if @referrer and (team_param = params[:team_param]).present?
        @referrer = rewrite_url(@referrer, { team_param => @team.id }) rescue nil
      end
      redirect_to @referrer || team_path(@team), :flash => {:success => "The team '#{@team.name}' has been created"}
    else
      render :new
    end
  end

  def delete
    @team = Team.find(params[:id].to_s, :as => current_user)
  end

  def destroy
    @team = Team.find(params[:id].to_s, :as => current_user)
    if @team.destroy
      redirect_to teams_path, :flash => {:success => "The team '#{@team.name}' has been deleted"}
    else
      render :delete
    end
  end

  protected
    def active_tab
      :settings unless ['show', 'index'].include? action_name
    end

    def rewrite_url(url, query)
      url = URI(url) unless url.is_a? URI
      url.query = Rack::Utils.parse_query(url.query).merge(query).select {|k,v| v != nil }.to_query
      url.to_s
    end
end
