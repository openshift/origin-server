class MembersController < BaseController

  def index
    render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Found #{pluralize(members.length, 'member')}.")
  end

  def create
    authorize! :change_members, membership

    ids, logins, remove = {}, {}, []
    members_params = (params[:members] || [params[:member]].compact.presence || [params.slice(:id, :login, :role)]).compact
    members_params.each do |m| 
      return render_error(:unprocessable_entity, "You must provide a member with an id and role.") unless m.is_a? Hash
      if m[:role] == "none"
        return render_error(:unprocessable_entity, "You must provide an id for each member with role 'none'.") unless m[:id]
        remove << m[:id].to_s
        next
      end
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

    if ids.present? or logins.present?
      new_members = CloudUser.accessible(current_user).with_ids_or_logins(ids.keys, logins.keys).each.to_a.map do |u| 
        m = u.as_member
        m.role = ids[u._id.to_s] || logins[u.login.to_s]
        m
      end
    else
      new_members = []
    end

    if remove.blank? and new_members.blank?
      return render_error(:not_found, "The specified user was not found.") if members_params.count == 1
      return render_error(:unprocessable_entity, "You must provide at least a single member.")
    end

    count_remove = remove.count
    count_update = (membership.member_ids & new_members.map(&:id)).count
    count_add    = new_members.count - count_update

    membership.remove_members(remove) if remove.present?
    membership.add_members(new_members) if new_members.present?

    if save_membership(membership)
      msg = [
        ("added #{pluralize(count_add,      'member')}" if count_add > 0),
        ("updated #{pluralize(count_update, 'member')}" if count_update > 0),
        ("removed #{pluralize(count_remove, 'member')}" if count_remove > 0)
      ].compact.join(", ").humanize + '.'

      if (count_add + count_update == 1) and (count_remove == 0) and (member = members.select {|m| m._id == new_members.first._id }.first)
        render_success(:ok, "member", get_rest_member(member), msg)
      else
        render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, msg)
      end
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