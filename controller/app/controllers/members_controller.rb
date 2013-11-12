class MembersController < BaseController

  def index
    render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Found #{pluralize(members.length, 'member')}.")
  end

  def create
    authorize! :change_members, membership

    errors = []
    warnings = []
    singular = params[:members].nil?
    ids, logins = {}, {}

    # Find input members
    members_params = (params[:members] || [params[:member]].compact.presence || [params.slice(:id, :login, :role)]).compact
    members_params.each_with_index do |m, i|
      errors << Message.new(:error, "You must provide a member with an id and role.", 1, nil, i) and next unless m.is_a? Hash
      role = Role.for(m[:role]) || (m[:role] == 'none' and :none)
      errors << Message.new(:error, "You must provide a role for each member - you can add or update (with #{Role.all.map{ |s| "'#{s}'" }.join(', ')}) or remove (with 'none').", 1, :role, i) and next unless role
      if m[:id].present?
        ids[m[:id].to_s] = [role, i]
      elsif m[:login].present?
        logins[m[:login].to_s] = [role, i]
      else
        errors << Message.new(:error, "Each member being changed must have an id or a login.", 1, nil, i)
      end
    end
    if errors.present?
      Rails.logger.error errors
      return render_error(:bad_request, errors.first.text, nil, nil, nil, errors) if singular
      return render_error(:bad_request, "The provided members are not valid.", nil, nil, nil, errors)
    end
    return render_error(:unprocessable_entity, "You must provide at least a single member that exists.") unless ids.present? || logins.present?

    # Perform lookups of users by login and create members for new roles
    new_members = changed_members_for(ids, logins, errors)
    remove = removed_ids(ids, logins, errors)
    if errors.present?
      return render_error(:not_found, errors.first.text, nil, nil, nil, errors) if singular
      return render_error(:not_found, "Not all provided members exist.", nil, nil, nil, errors)
    end

    # Warn about partial inputs
    invalid_members = []
    remove.delete_if do |id, pretty|
      unless membership.member_ids.detect{ |m| m === id }
        invalid_members << pretty
      end
    end
    if invalid_members.present?
      msg = "#{invalid_members.to_sentence} #{invalid_members.length > 1 ? "are not members" : "is not a member"} and cannot be removed."
      return render_error(:bad_request, msg) if singular
      warnings << Message.new(:warning, msg, 1, nil)
    end

    count_remove = remove.count
    count_update = (membership.member_ids & new_members.map(&:id)).count
    count_add    = new_members.count - count_update

    membership.remove_members(remove.keys)
    membership.add_members(new_members)

    if save_membership(membership)
      msg = [
        ("added #{pluralize(count_add,      'member')}" if count_add > 0),
        ("updated #{pluralize(count_update, 'member')}" if count_update > 0),
        ("removed #{pluralize(count_remove, 'member')}" if count_remove > 0),
        ("ignored #{pluralize(invalid_members.length, 'missing member')} (#{invalid_members.join(', ')})" if invalid_members.present?),
      ].compact.join(", ").humanize + '.'

      if (count_add + count_update == 1) and (count_remove == 0) and (member = members.detect{|m| m._id == new_members.first._id })
        render_success(:ok, "member", get_rest_member(member), msg, nil, warnings)
      else
        render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, msg, nil, warnings)
      end
    else
      render_error(:unprocessable_entity, "The members could not be added due to validation errors.", nil, nil, nil, get_error_messages(membership))
    end
  end

  def destroy
    authorize! :change_members, membership
    remove_member(params[:id])
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

  def leave
    authorize! :leave, membership
    return render_error(:bad_request, "You are the owner of this #{membership.class.model_name.humanize.downcase} and cannot leave.") if membership.owned_by?(current_user)
    remove_member(current_user._id)
  end

  protected
    def membership
      raise "Must be implemented to return the resource under access control"
    end

    def remove_member(id)
      membership.remove_members(id)
      if save_membership(membership)
        if m = members.detect{ |m| m._id === id }
          render_success(:ok, "member", get_rest_member(m), nil, nil, Message.new(:info, "The member #{m.name} is no longer directly granted a role.", 132))
        else
          render_success(requested_api_version <= 1.4 ? :no_content : :ok, nil, nil, "Removed member.")
        end
      else
        render_error(:unprocessable_entity, "The member could not be removed due to an error.", nil, nil, nil, get_error_messages(membership))
      end
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
    def changed_members_for(ids, logins, errors)
      if ids.present? or logins.present?
        ids = ids.select{ |id, (role, _)| role != :none }
        logins = logins.select{ |id, (role, _)| role != :none }
        users = CloudUser.accessible(current_user).with_ids_or_logins(ids.keys, logins.keys).each.to_a
        missing_user_logins(errors, users, logins)
        missing_user_ids(errors, users, ids)
        users.map do |u|
          m = u.as_member
          m.role = (ids[u._id.to_s] || logins[u.login.to_s])[0]
          m
        end
      else
        []
      end
    end

    def removed_ids(ids, logins, errors)
      ids = ids.inject({}){ |h, (id, (role, _))| h[id] = id if role == :none; h }
      logins = logins.select{ |id, (role, _)| role == :none }
      if logins.present?
        users = CloudUser.accessible(current_user).with_ids_or_logins(nil, logins.keys).each.to_a
        missing_user_logins(errors, users, logins)
        ids.merge!(users.inject({}){ |h, u| h[u._id.to_s] = u.login; h })
      end
      ids
    end

    def missing_user_logins(errors, users, map)
      (map.keys - users.map(&:login)).each do |login|
        errors << Message.new(:error, "There is no account with login #{login}.", 132, :login, map[login].last)
      end
    end

    def missing_user_ids(errors, users, map)
      (map.keys - users.map{ |u| u._id.to_s }).each do |id|
        errors << Message.new(:error, "There is no account with identifier #{id}.", 132, :id, map[id].last)
      end
    end

    include ActionView::Helpers::TextHelper
end