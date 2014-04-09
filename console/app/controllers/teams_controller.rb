class TeamsController < ConsoleController
  def index
    if params[:owner] == '@self'
      @teams = Team.find(:all, :params => {:owner => "@self"}, :as => current_user)
    elsif params[:search]
      if params[:search].to_s.length >= 2
        @teams = (Team.find(:all, :params => {:global => params[:global] == 'true', :search => params[:search]}, :as => current_user) rescue [])
      else
        @teams = []
      end
    else
      @teams = Team.find(:all, :as => current_user)
    end

    respond_to do |format|
      format.json { render :json => @teams.map {|t| {:id => t.id, :name => t.name} } }
      format.html { render }
    end    
  end

end
