class MembersController < ConsoleController
  def index
    @membership = membership
    @members = @membership.members
  end

  def update
    new_members = Array(params[:members]).map {|m| new_member(m) }
    if new_members.present?
      if membership.update_members(new_members)
        flash[:success] = membership.messages.first.presence || "Updated members"
      else
        flash[:error] = membership.messages.first.presence || "Could not update members"
      end
    end
    redirect_to :action => :index
  end

  def create
    @member = new_member(params[:member])
    # TODO: handle access control error
    # TODO: handle user already a member with higher permission
    # TODO: handle user already a member with higher permission via a group
    if @member.save
      flash[:success] = @member.messages.first.presence || "Added member to domain"
      redirect_to :action => :index
    else
      @membership = membership
      @members = @membership.members
      render :index
    end
  end

  protected
    def membership
      @membership ||= Domain.find(params[:domain_id], :as => current_user)
    end

    def new_member(params={})
      member = Member.new(params)
      member.domain = membership
      member
    end

end
