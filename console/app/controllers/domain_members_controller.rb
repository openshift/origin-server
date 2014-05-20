class DomainMembersController < MembersController

  protected
    def show_edit_with_errors(members)
      @capabilities = user_capabilities
      @new_members = members.select {|m| m.attributes[:adding] }
      render :template => 'domains/show' and return
    end

    def left_path
      console_path
    end

    def membership
      @domain ||= Domain.find(params[:domain_id], :params => {:include => :application_info}, :as => current_user)
    end

    def new_member(params={})
      member = Domain::Member.new(params)
      member.domain = membership
      member
    end

end
