class MembersController < ConsoleController

  def index
    redirect_to url_for(membership)
  end

  def update
    # Support :members as hash or array
    p = params[:members] || []
    p = [p] unless p.is_a? Array
    members = p.map {|m| new_member(m) }
    # Ignore member rows without a login or id specified
    members = members.select {|m| m.login.present? || m.id.present? }

    if members.present?
      if membership.update_members(members)
        flash[:success] = membership.messages.first.presence || "Updated members"
      else
        flash.now[:error] = membership.errors[:members].first || "Could not update members."
        show_edit_with_errors(members)
        return
      end
    end
    redirect_to url_for(membership)
  end

  def leave
    if request.post?
      if membership.leave
        flash[:success] = membership.messages.first.presence || "You are no longer a member of '#{membership.name}'"
        redirect_to left_path
      else
        flash[:error] = membership.errors[:base].first.presence || membership.messages.first.presence || "Could not leave '#{membership.name}'"
        redirect_to url_for(membership)
      end
    else
      render "leave_#{membership.class.model_name.downcase}"
    end
  end

  protected
    def show_edit_with_errors(members)
      raise "unimplemented"
    end

    def left_path
      raise "unimplemented"
    end

    def membership
      raise "unimplemented"
    end

    def new_member(params={})
      raise "unimplemented"
    end

end
