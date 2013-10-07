class MembersController < ConsoleController

  def index
    redirect_to domain_path(params[:domain_id])
  end

  def update
    @domain = get_domain

    # Support :members as hash or array
    p = params[:members] || []
    p = [p] unless p.is_a? Array
    members = p.map {|m| new_member(m) }
    # Ignore new member rows without a login specified
    members = members.select {|m| m.login.present? || m.id.present? }

    if members.present?
      if @domain.update_members(members)
        flash[:success] = @domain.messages.first.presence || "Updated members"
      else
        flash.now[:error] = "Could not update members."
        @capabilities = user_capabilities
        @new_members = members.select {|m| m.login.present? and m.id.blank? }
        render :template => 'domains/show' and return
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
