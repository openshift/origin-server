class ChangeMembersDomainOp < PendingDomainOps

  field :members_added, type: Array
  field :members_removed, type: Array
  field :roles_changed, type: Array

  def execute
    self.domain.applications.select do |a|
      a.change_member_roles(roles_changed || [], [:domain])
      a.remove_members(members_removed || [], [:domain])
      a.add_members((members_added || []).map{ |m| Domain.to_member(m) }, [:domain])
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
