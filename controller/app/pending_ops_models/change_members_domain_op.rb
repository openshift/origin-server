class ChangeMembersDomainOp < PendingDomainOps

  field :members_added, type: Array
  field :members_removed, type: Array
  field :roles_changed, type: Array

  def execute
    user_roles_changed   = (roles_changed   || []).select {|(id, type, *_)| type == 'user' }
    user_members_removed = (members_removed || []).select {|(id, type, *_)| type == 'user' }
    user_members_added   = (members_added || []).select {|(id, type, *_)| type == 'user' }

    self.domain.applications.select do |a|
      a.change_member_roles(user_roles_changed || [], [:domain])
      a.remove_members(user_members_removed || [], [:domain])
      a.add_members((user_members_added || []).map{ |m| Domain.to_member(m) }, [:domain])
      if a.has_member_changes?
        a.save!
      end
    end.each do |app|
      # only run jobs on applications that had changes
      app.with_lock{ |a| a.run_jobs }
    end
    set_state(:completed)
  end
end
