class MembersController < BaseController

  def index
    render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, "Found #{pluralize(members.length, 'member')}.")
  end
  
  def show
    id = params[:id].presence
    type = params[:type].presence
    member = membership.members.find_by({:id => id,:type => type == 'user' ? nil : type})
    return render_error(:not_found, "Could not find member #{id}", 1) if member.nil?
    render_success(:ok, "member", get_rest_member(member), "Showing member #{id}")
  end

  def create
    authorize! :change_members, membership

    errors = []
    warnings = []
    singular = params[:members].nil?
    user_ids, user_logins, team_ids, team_names = {}, {}, {}, {}

    # Find input members
    members_params = (params[:members] || [params[:member]].compact.presence || [params.slice(:id, :login, :name, :type, :role)]).compact
    members_params.each_with_index do |m, i|
      errors << Message.new(:error, "You must provide a member with an id and role.", 1, nil, i) and next unless m.is_a? Hash
      role = Role.for(m[:role]) || (m[:role] == 'none' and :none)
      errors << Message.new(:error, "You must provide a role for each member - you can add or update (with #{Role.all.map{ |s| "'#{s}'" }.join(', ')}) or remove (with 'none').", 1, :role, i) and next unless role
      type = m[:type] || "user"
      case type
      when "user"
        if m[:id].present?
          user_ids[m[:id].to_s] = [role, i]
        elsif m[:login].present?
          user_logins[m[:login].to_s] = [role, i]
        else
          errors << Message.new(:error, "Each user being changed must have an id or a login.", 1, nil, i)
        end
      when "team"
        if m[:id].present?
          team_ids[m[:id].to_s] = [role, i]
        elsif m[:name].present?
          team_names[m[:name].to_s] = [role, i]
        else
          errors << Message.new(:error, "Each team being changed must have an id or a name.", 1, nil, i)
        end
      else
        errors << Message.new(:error, "Unrecognized type '#{type}'.  Expecting user or team.", 1, nil, i)
      end
    end
    if errors.present?
      Rails.logger.error errors
      return render_error(:unprocessable_entity, errors.first.text, 1, nil, nil, errors) if singular
      return render_error(:unprocessable_entity, "The provided members are not valid.", 1, nil, nil, errors)
    end
    return render_error(:unprocessable_entity, "You must provide at least a single member that exists.", 1) unless user_ids.present? || user_logins.present? || team_ids.present? || team_names.present?

    # Perform lookups of users by login and create members for new roles
    new_members = changed_members_for(user_ids, user_logins, team_ids, team_names, errors)
    remove = removed_ids(user_ids, user_logins, team_ids, team_names, errors)
    if errors.present?
      return render_error(:not_found, errors.first.text, 1, nil, nil, errors) if singular
      return render_error(:not_found, "Not all provided members exist.", 1, nil, nil, errors)
    end

    # Warn about partial inputs
    invalid_members = []
    remove[:users].delete_if do |id, pretty|
      unless membership.members.detect{ |m| m._id.to_s == id and (m.type == "user" or m.type == nil) and m.from.blank?}
        invalid_members << pretty
      end
    end
    remove[:teams].delete_if do |id, pretty|
      unless membership.members.detect{ |m| m._id.to_s == id and m.type == "team"}
        invalid_members << pretty
      end
    end
    if invalid_members.present?
      msg = "#{invalid_members.to_sentence} #{invalid_members.length > 1 ? "are not direct members" : "is not a direct member"} and cannot be removed."
      return render_error(:unprocessable_entity, msg, 1) if singular
      warnings << Message.new(:warning, msg, 1, nil)
    end

    count_remove = remove[:users].count + remove[:teams].count
    count_update = (membership.member_ids & new_members.map(&:id)).count
    count_add    = new_members.count - count_update
    membership.remove_members(remove[:users].map {|k,v| [k, "user"]} + remove[:teams].map {|k,v| [k, "team"]})
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
      render_error(:unprocessable_entity, "The members could not be added due to validation errors.", 1, nil, nil, get_error_messages(membership))
    end
  end
  
  def update
    authorize! :change_members, membership
    id = params[:id].presence
    role = params[:role].presence 
    type = params[:type].presence
    member = membership.members.find_by({:id => id,:type => type == 'user' ? nil : type})
    if role.to_sym == :none
      membership.remove_members(member)
    else
      membership.add_members(member.clone.clear, role.to_sym)
    end
    membership.save!
    member = membership.members.find_by({:id => id,:type => type == 'user' ? nil : type}) unless role.to_sym == :none
    render_success(:ok, "member", role.to_sym == :none ? nil : get_rest_member(member), "Updated member")
  end

  def destroy
    if params[:id] == "self"
      leave
    else
      authorize! :change_members, membership
      id = params[:id].presence
      type = params[:type].presence || "user"
      remove_member(id, type)
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
      render_success(:ok, "members", members.map{ |m| get_rest_member(m) }, ids.blank? ? "Reverted members to the defaults." : "Removed or reset #{pluralize(ids.length, 'member')}.")
    else
      render_error(:unprocessable_entity, "The members could not be removed due to an error.", 1, nil, nil, get_error_messages(membership))
    end
  end

  def leave
    authorize! :leave, membership
    return render_error(:unprocessable_entity, "You are the owner of this #{membership.class.model_name.humanize.downcase} and cannot leave.", 1) if membership.owned_by?(current_user)
    remove_member(current_user._id)
  end

  protected
    def membership
      raise "Must be implemented to return the resource under access control"
    end

    def remove_member(id, type="user")
      member = membership.members.find_by({:id => id,:type => type == 'user' ? nil : type})
      membership.remove_members(member)
      if save_membership(membership)
        if m = members.detect{ |m| m._id === id }
          render_success(:ok, "member", get_rest_member(m), nil, nil, Message.new(:info, "The member #{m.name} is no longer directly granted a role.", 132))
        else
          render_success(requested_api_version <= 1.4 ? :no_content : :ok, nil, nil, "Removed member.")
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

  private
    def changed_members_for(user_ids, user_logins, team_ids, team_names, errors)
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
      if team_ids.present? or team_names.present?
        team_ids = team_ids.select{ |id, (role, _)| role != :none }
        team_names = team_names.select{ |id, (role, _)| role != :none }
        teams = Team.where(owner_id: current_user._id).with_ids_or_names(team_ids.keys, team_names.keys).each.to_a
        missing_team_names(errors, teams, team_names)
        missing_team_ids(errors, teams, team_ids)
        teams.map do |t|
          m = t.as_member
          m.role = (team_ids[t._id.to_s] || team_names[t.name.to_s])[0]
          changed_members.push(m)
        end
      end
      changed_members
    end

    def removed_ids(user_ids, user_logins, team_ids, team_names, errors)
      user_ids = user_ids.inject({}){ |h, (id, (role, _))| h[id] = id if role == :none; h }
      user_logins = user_logins.select{ |id, (role, _)| role == :none }
      if user_logins.present?
        users = CloudUser.accessible(current_user).with_ids_or_logins(nil, user_logins.keys).each.to_a
        missing_user_logins(errors, users, user_logins)
        user_ids.merge!(users.inject({}){ |h, u| h[u._id.to_s] = u.login; h })
      end
      team_ids = team_ids.inject({}){ |h, (id, (role, _))| h[id] = id if role == :none; h }
      team_names = team_names.select{ |id, (role, _)| role == :none }
      if team_names.present?
        teams = Team.where(owner_id: current_user._id).with_ids_or_names(nil, team_names.keys).each.to_a
        missing_team_names(errors, teams, team_names)
        team_ids.merge!(teams.inject({}){ |h, t| h[t._id.to_s] = t.name; h })
      end
      {:users => user_ids, :teams => team_ids}
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
    
    def missing_team_names(errors, teams, map)
      (map.keys - teams.map(&:name)).each do |name|
        errors << Message.new(:error, "There is no team with name #{name}.", 132, :name, map[name].last)
      end
    end

    def missing_team_ids(errors, teams, map)
      (map.keys - teams.map{ |t| t._id.to_s }).each do |id|
        errors << Message.new(:error, "There is no team with identifier #{id}.", 132, :id, map[id].last)
      end
    end

    include ActionView::Helpers::TextHelper
end