class MembersController < BaseController

  def index
    render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Found #{pluralize(members.length, 'member')}.")
  end

  def show
    id = params[:id].presence
    type = params[:type].presence || "user"
    member = find_existing_member(id, type)
    return render_error(:not_found, "Could not find member #{id}", 1) if member.nil?
    render_success(:ok, "member", get_rest_member(member), "Showing member #{id}")
  end

  def create
    authorize! :change_members, membership

    errors = []
    warnings = []
    singular = params[:members].nil?
    user_ids, user_logins, team_ids = {}, {}, {}, {}

    # Find input members
    members_params = (params[:members] || [params[:member]].compact.presence || [params.slice(:id, :login, :type, :role)]).compact
    members_params.each_with_index do |m, i|
      errors << Message.new(:error, "You must provide a member with an id and role.", 1, nil, i) and next unless m.is_a? Hash
      role = Role.for(m[:role]) || (m[:role] == 'none' and :none)
      errors << Message.new(:error, "You must provide a role for each member - you can add or update (with #{allowed_roles.map{ |s| "'#{s}'" }.join(', ')}) or remove (with 'none').", 1, "role", i) and next unless role
      errors << Message.new(:error, "Role #{role} not supported for #{membership.class.model_name.humanize.downcase}. Supported roles are #{allowed_roles.map{ |s| "'#{s}'" }.join(', ')}.", 1, "role", i) and next unless allowed_roles.include?(role) or role == :none
      type = m[:type] || "user"
      errors << Message.new(:error, "Members of type #{type} not supported for #{membership.class.model_name.humanize.downcase}. Supported types are #{allowed_member_types.map{ |s| "'#{s}'" }.join(', ')}.", 1, "type", i) and next unless allowed_member_types.include?(type)
      case type
      when "user"
        if m[:id].present?
          user_ids[m[:id].to_s] = [role, i]
        elsif m[:login].present?
          user_logins[CloudUser.normalize_login(m[:login])] = [role, i]
        else
          errors << Message.new(:error, "Each user being changed must have an id or a login.", 1, nil, i)
        end
      when "team"
        if m[:id].present?
          team_ids[m[:id].to_s] = [role, i]
        else
          errors << Message.new(:error, "Each team being changed must have an id.", 1, nil, i)
        end
      else
        errors << Message.new(:error, "Type '#{type}' not implemented.", 1, "type")
      end
    end
    if errors.present?
      Rails.logger.error errors
      return render_error(:unprocessable_entity, errors.first.text, 1, nil, nil, errors) if singular
      return render_error(:unprocessable_entity, "The provided members are not valid.", 1, nil, nil, errors)
    end
    return render_error(:unprocessable_entity, "You must provide at least a single member that exists.", 1) unless user_ids.present? || user_logins.present? || team_ids.present?

    # Perform lookups of users by login and create members for new roles
    new_members = changed_members_for(user_ids, user_logins, team_ids, errors)
    remove = removed_ids(user_ids, user_logins, team_ids, errors)

    if errors.present?
      Rails.logger.error errors
      return render_error(:not_found, errors.first.text, 1, nil, nil, errors) if singular
      return render_error(:not_found, "Not all provided members exist.", 1, nil, nil, errors)
    end

    # Warn about partial inputs
    invalid_members = []
    indirect_members = []
    #filter of what can be removed and generate error for the rest
    remove = remove.select {|r| can_be_removed?(r[0], r[1], r[3], invalid_members, indirect_members) }

    if invalid_members.present?
      msg = "#{invalid_members.to_sentence} #{invalid_members.length > 1 ? "are not members" : "is not a member"} and cannot be removed."
      return render_error(:unprocessable_entity, msg, 1) if singular
      warnings << Message.new(:warning, msg, 1, nil)
    end

    if indirect_members.present?
      msg = "#{indirect_members.to_sentence} #{indirect_members.length > 1 ? "are not direct members" : "is not a direct member"} and cannot be removed."
      return render_error(:unprocessable_entity, msg, 1) if singular
      warnings << Message.new(:warning, msg, 1, nil)
    end

    count_remove = remove.count
    count_update = (membership.members.map(&:to_key) & new_members.map(&:to_key)).count
    count_add    = new_members.count - count_update
    membership.remove_members(remove)
    membership.add_members(new_members)

    if save_membership(membership)
      msg = [
        ("added #{pluralize(count_add,      'member')}" if count_add > 0),
        ("updated #{pluralize(count_update, 'member')}" if count_update > 0),
        ("removed #{pluralize(count_remove, 'member')}" if count_remove > 0),
        ("ignored #{pluralize(invalid_members.length, 'missing member')} (#{invalid_members.join(', ')})" if invalid_members.present?),
      ].compact.join(", ").humanize + '.'

      props = {'membership_type' => membership.class.name}
      props['members_added_count'] = count_add if count_add > 0
      props['members_updated_count'] = count_update if count_update > 0
      props['members_removed_count'] = count_remove if count_remove > 0
      @analytics_tracker.track_event('members_modify', membership, nil, props)

      if (count_add + count_update == 1) and (count_remove == 0) and (member = members.detect{|m| m._id == new_members.first._id })
        render_success(:ok, "member", get_rest_member(member), msg, nil, warnings)
      else
        render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, msg, nil, warnings)
      end
    else
      render_error(:unprocessable_entity, "The members could not be added due to validation errors.", 1, nil, nil, get_error_messages(membership))
    end
  end

  def update
    authorize! :change_members, membership
    id = params[:id].presence
    role = params[:role].presence
    return render_error(:unprocessable_entity, "You must provide a role. Supported_roles are (#{allowed_roles.map{ |s| "'#{s}'" }.join(', ')}) or remove (with 'none').", 1, "role") unless role.present?
    return render_error(:unprocessable_entity, "Role #{role} not supported. Supported roles are (#{allowed_roles.map{ |s| "'#{s}'" }.join(', ')}).", 1, "role") unless allowed_roles.include? (role.to_sym) or role.to_sym == :none
    type = params[:type].presence || "user"
    return render_error(:unprocessable_entity, "Member type #{type} not supported. Supported types are #{allowed_member_types.map{ |s| "'#{s}'" }.join(', ')}.", 1, "type") unless allowed_member_types.include? (type)
    member = find_existing_member(id, type)
    props = {'membership_type' => membership.class.name}
    if role.to_sym == :none
      membership.remove_members(member)
      props['members_removed_count'] = 1
    else
      membership.add_members(member.clone.clear, role.to_sym)
      props['members_added_count'] = 1
    end
    membership.save!

    @analytics_tracker.track_event('members_modify', membership, nil, props)

    member = find_existing_member(id, type) unless role.to_sym == :none
    render_success(:ok, "member", role.to_sym == :none ? nil : get_rest_member(member), "Updated member")
  end

  def destroy
    authorize! :change_members, membership
    id = params[:id].presence
    type = params[:type].presence || "user"
    return render_error(:unprocessable_entity, "Member type #{type} not supported. Supported types are #{allowed_member_types.map{ |s| "'#{s}'" }.join(', ')}.", 1, "type") unless allowed_member_types.include? (type)
    remove_member(id, type)

    @analytics_tracker.track_event('members_modify', membership, nil, {'membership_type' => membership.class.name, 'members_removed_count' => 1})
  end

  def destroy_all
    authorize! :change_members, membership

    ids, logins = [], []
    (params[:members].presence || [params[:member].presence] || []).compact.each do |m|
      if m.is_a?(Hash)
        if m[:id].present?
          ids << m[:id].to_s
        elsif m[:login].present?
          logins << CloudUser.normalize_login(m[:login])
        else
          return render_error(:unprocessable_entity, "Each member must have an id or a login.", 1)
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
      @analytics_tracker.track_event('members_modify', membership, nil, {'membership_type' => membership.class.name, 'members_removed_count' => ids.length})

      render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, ids.blank? ? "Reverted members to the defaults." : "Removed or reset #{pluralize(ids.length, 'member')}.")
    else
      render_error(:unprocessable_entity, "The members could not be removed due to an error.", 1, nil, nil, get_error_messages(membership))
    end
  end

  def leave
    authorize! :leave, membership
    return render_error(:unprocessable_entity, "You are the owner of this #{membership.class.model_name.humanize.downcase} and cannot leave.", 1) if membership.owned_by?(current_user)
    remove_member(current_user._id)
    @analytics_tracker.track_event('members_modify', membership, nil, {'membership_type' => membership.class.name, 'members_removed_count' => 1})
  end

  protected
    def membership
      raise "Must be implemented to return the resource under access control"
    end

    def remove_member(id, type="user")
      member = find_existing_member(id, type)

      is_self = type == 'user' && id == current_user._id
      if !member.explicit_role?
        if is_self
          msg = "You are not a direct member of this #{membership.class.model_name.humanize.downcase} and cannot leave."
        else
          msg = "The member #{member.name} is not a direct member of this #{membership.class.model_name.humanize.downcase} and cannot be removed."
        end
        return render_error(:unprocessable_entity, msg, 1)
      end

      membership.remove_members(member)
      if save_membership(membership)
        if m = members.detect{ |m| m._id === id }
          if is_self
            msg = "You are still an indirect member of the #{membership.class.model_name.humanize.downcase}."
          else
            msg = "The member #{m.name} is still an indirect member of the #{membership.class.model_name.humanize.downcase}."
          end
          render_success(:ok, "member", get_rest_member(m), nil, nil, Message.new(:warn, msg, 132))
        else
          render_success(requested_api_version <= 1.4 ? :no_content : :ok, nil, nil, is_self ? "You are no longer a member." : "Removed member.")
        end
      else
        render_error(:unprocessable_entity, "The member could not be removed due to an error.", 1, nil, nil, get_error_messages(membership))
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
      RestMember.new(m, is_owner?(m), get_url, membership, nolinks)
    end

    def is_owner?(member)
      membership.owner_id == member._id
    end

    def members
      membership.members
    end

    def allowed_roles
      Role.all
    end

    def allowed_member_types
      ["user", "team"]
    end

  private
    def find_existing_member(id, type)
      membership.members.find_by({:id => id, :type => type == 'user' ? nil : type})
    end

    def changed_members_for(user_ids, user_logins, team_ids, errors)
      changed_members = []
      if user_ids.present? or user_logins.present?
        user_ids = user_ids.select{ |id, (role, _)| role != :none }
        user_logins = user_logins.select{ |id, (role, _)| role != :none }
        users = CloudUser.accessible(current_user).with_ids_or_logins(user_ids.keys, user_logins.keys).each.to_a
        missing_user_logins(errors, users, user_logins)
        missing_user_ids(errors, users, user_ids)
        users.map do |u|
          m = u.as_member
          m.role = (user_ids[u._id.to_s] || user_logins[u.login.to_s])[0]
          changed_members.push(m)
        end
      end
      if team_ids.present?
        team_ids = team_ids.select{ |id, (role, _)| role != :none }
        teams = Team.accessible(current_user).with_ids(team_ids.keys).each.to_a
        missing_team_ids(errors, teams, team_ids)
        teams = teams.select {|t| is_owner_or_global_or_already_exists?(errors, t)}
        teams.map do |t|
          m = t.as_member
          m.role = (team_ids[t._id.to_s])[0]
          changed_members.push(m)
        end
      end
      changed_members
    end

    def removed_ids(user_ids, user_logins, team_ids, errors)
      remove_ids = []
      user_ids = user_ids.select{ |id, (role, _)| role == :none }
      user_ids.each { |k,v| remove_ids << [k, "user", nil, k] }
      user_logins = user_logins.select{ |id, (role, _)| role == :none }
      if user_logins.present?
        users = CloudUser.accessible(current_user).with_ids_or_logins(nil, user_logins.keys).each.to_a
        missing_user_logins(errors, users, user_logins)
        users.each { |u| remove_ids << [u.id.to_s, "user", nil, u.login]}
      end
      team_ids = team_ids.select{ |id, (role, _)| role == :none }
      team_ids.each { |k,v| remove_ids << [k, "team", nil, k]}
      remove_ids
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

    def missing_team_ids(errors, teams, map)
      (map.keys - teams.map{ |t| t._id.to_s }).each do |id|
        errors << Message.new(:error, "There is no team with identifier #{id}.", 132, :id, map[id].last)
      end
    end

    def is_owner_or_global_or_already_exists?(errors, team)
      if team.owner_id == current_user._id or existing_team_member_ids.include?(team.id) or team.owner_id.nil?
        return true
      else
        errors << Message.new(:error, "You cannot add the team '#{team.name}' because you are not the owner.", 132, "id")
        return false
      end
    end

    def can_be_removed?(id, type, pretty, invalid_members, indirect_members)
      member = find_existing_member(id, type) rescue nil
      if member
        if member.explicit_role?
          return true
        else
          indirect_members << (member.name || member.login || pretty)
          return false
        end
      else
        invalid_members << pretty
        return false
      end
    end

    def existing_team_member_ids
      @existing_team_member_ids ||= membership.members.select(&:team?).map(&:id)
    end

    include ActionView::Helpers::TextHelper
end
