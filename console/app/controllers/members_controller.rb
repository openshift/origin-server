class MembersController < ConsoleController

  def create
    @member = new_member(params[:domain_member])
    if @member.save
      flash[:success] = @member.messages.first.presence || "Added member to domain"
      redirect_to domain_path(get_domain)
    else
      @domain = get_domain
      render :template => 'domains/show'
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
    redirect_to domain_path(@domain)
  end

  def leave
    @domain = get_domain
    if request.post?
      if @domain.leave
        flash[:success] = "You are no longer a member of the domain '#{@domain.name}'"
        redirect_to console_path
      else
        flash[:error] = @domain.messages.first.presence || "Could not leave the domain '#{@domain.name}'"
        redirect_to domain_path(@domain)
      end
    end
  end

  protected
    def get_domain
      @domain ||= Domain.find(params[:domain_id], :params => {:include => :application_info}, :as => current_user)
    end

    def new_member(params={})
      member = Domain::Member.new(params)
      member.domain = get_domain
      member
    end

end
