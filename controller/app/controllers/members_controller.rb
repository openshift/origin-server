class MembersController < BaseController

  def index
    render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Found #{pluralize(members.length, 'member')}.")
  end

  def create
    authorize! :change_members, membership

    ids, logins = {}, {}
    (params[:members].presence || [params[:member].presence] || []).compact.each do |m| 
      return render_error(:unprocessable_entity, "You must provide a member with an id and role.") unless m.is_a? Hash
      role = Role.for(m[:role])
      return render_error(:unprocessable_entity, "You must provide a role for each member out of #{Role.all.join(', ')}.") unless role
      if m[:id].present?
        ids[m[:id].to_s] = role
      elsif m[:login].present?
        logins[m[:login].to_s] = role
      else
        return render_error(:unprocessable_entity, "Each member must have an id or a login.")
      end
    end

    new_members = Array(CloudUser.accessible(current_user).with_ids_or_logins(ids.keys, logins.keys).find_by).map do |u| 
      m = u.as_member
      m.role = ids[u._id] || logins[u.login]
      m
    end
    return render_error(:unprocessable_entity, "You must provide at least a single member.") if new_members.blank?

    membership.add_members(new_members)

    if save_membership(membership)
      render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Added #{pluralize(new_members.length, 'member')}.")
    else
      render_error(:unprocessable_entity, "The members could not be added due to validation errors.", nil, nil, nil, new_members.map{ |m| get_error_messages(m) }.flatten)
    end
  end

  def destroy
    authorize! :change_members, membership

    membership.remove_members(params[:id])

    if save_membership(membership)
      if m = members.detect{ |m| m._id === params[:id] }
        render_success(:ok, "member", get_rest_member(m), "The member #{m.name} is no longer directly granted a role.")
      else
        render_success(:no_content, nil, nil, "Removed member.")
      end
    else
      render_error(:unprocessable_entity, "The member could not be removed due to an error.", nil, nil, nil, get_error_messages(membership))
    end
  end

  def destroy_all
    authorize! :change_members, membership

    ids, logins = [], []
    (params[:members].presence || [params[:member].presence] || []).compact.each do |m| 
      if m.is_a?(Hash) 
        if m[:id].present?
          ids << m[:id].to_s
        elsif m[:login].present?
          logins << m[:login].to_s
        else
          return render_error(:unprocessable_entity, "Each member must have an id or a login.")
        end
      else
        ids << m.to_s
      end
    end
    ids.concat(CloudUser.in(login: logins).map(&:_id)) if logins.present?

    if ids.blank?
      membership.reset_members
    else
      membership.remove_members(*ids)
    end

    if save_membership(membership)
      render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, ids.blank? ? "Reverted members to the defaults." : "Removed or reset #{pluralize(ids.length, 'member')}.")
    else
      render_error(:unprocessable_entity, "The members could not be removed due to an error.", nil, nil, nil, get_error_messages(membership))
    end
  end

  protected
    def membership
      raise "Must be implemented to return the resource under access control"
    end

    #
    # Subclass if saving the resource requires any additional steps (Application.save needs to be
    # run with the application lock).  Should return the result of .save
    #
    def save_membership(resource)
      if resource.save
        resource.run_jobs
        true
      end
    end

    def get_rest_member(m)
      RestMember.new(m, is_owner?(m), get_url, nolinks)
    end

    def is_owner?(member)
      membership.owner_id == member._id
    end

    def members
      membership.members
    end

  private
    include ActionView::Helpers::TextHelper
end