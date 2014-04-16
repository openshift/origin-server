class ChangeMembersOpGroup < PendingAppOpGroup

  field :members_added, type: Array
  field :members_removed, type: Array
  field :roles_changed, type: Array

  def elaborate(app)
    set :rollback_blocked, true
    
    added_ids = (members_added || []).select{ |(id, type, role, *_)| (type == nil || type == 'user') && (role = app.role_for(id)) and Ability.has_permission?(id, :ssh_to_gears, Application, role, app) }.map(&:first)
    removed_ids = (members_removed || []).select{ |(id, type, *_)| type == nil || type == 'user' }.map(&:first)
    (roles_changed || []).each do |(id, type, from, to)|
      next if type != 'user'
      was = Ability.has_permission?(id, :ssh_to_gears, Application, from || app.default_role, app)
      is =  Ability.has_permission?(id, :ssh_to_gears, Application, to || app.default_role, app)
      next if is == was
      (is ? added_ids : removed_ids) << id
    end

    # FIXME this is an unbounded operation, all keys for all users added and removed to each gear.  need to optimize
    add_keys_attrs = CloudUser.members_of(added_ids).map{ |u| app.get_updated_ssh_keys(u.ssh_keys) }.flatten(1)
    remove_keys_attrs = CloudUser.members_of(removed_ids).map{ |u| app.get_updated_ssh_keys(u.ssh_keys) }.flatten(1)

    if add_keys_attrs.present? or remove_keys_attrs.present?
      ops = []
      app.gears.each do |gear|
        ops << UpdateAppConfigOp.new(
          add_keys_attrs: add_keys_attrs,
          remove_keys_attrs: remove_keys_attrs,
          gear_id: gear.id.to_s
        )
      end
      pending_ops.concat(ops)
    end
  end
end
