class MembersController < ConsoleController
  def index
    @domain = get_domain
    @members = @domain.members
  end

  def create
    @member = new_member(params[:member])
    if @member.save
      flash[:success] = @member.messages.first.presence || "Added member to domain"
      redirect_to :action => :index
    else
      @domain = get_domain
      @members = @domain.members
      render :index
    end
  end

  def update
    @domain = get_domain
    new_members = Array(params[:members] || params[:member] || params.slice(:id, :login, :role)).map {|m| new_member(m) }
    if new_members.present?
      if @domain.update_members(new_members)
        flash[:success] = @domain.messages.first.presence || "Updated members"
      else
        flash[:error] = @domain.messages.first.presence || "Could not update members"
      end
    end
    redirect_to :action => :index
  end

  def leave
    @domain = get_domain
    if @domain.leave
      flash[:success] = "Successfully left the domain '#{@domain.name}'"
      redirect_to console_path
    else
      flash[:error] = @domain.messages.first.presence || "Could not leave the domain '#{@domain.name}'"
      redirect_to :action => :index
    end
  end

  protected
    def get_domain
      @domain ||= Domain.find(params[:domain_id], :as => current_user)
    end

    def new_member(params={})
      member = Domain::Member.new(params)
      member.domain = get_domain
      member
    end

end
