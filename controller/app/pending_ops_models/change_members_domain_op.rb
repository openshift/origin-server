class ChangeMembersDomainOp < PendingDomainOps

  field :members_added, type: Array
  field :members_removed, type: Array
  field :roles_changed, type: Array

  def execute
    user_roles_changed   = (roles_changed   || []).select {|(id, type, *_)| type == 'user' }
    user_members_removed = (members_removed || []).select {|(id, type, *_)| type == 'user' }
    user_members_added   = (members_added   || []).select {|(id, type, *_)| type == 'user' }

    if [user_roles_changed, user_members_removed, user_members_added].any?(&:present?)
      pending_apps.each do |a| 
        a.with_lock do
          a.with_member_change_parent_op(self) do
            a.change_member_roles(user_roles_changed || [], [:domain])
            a.remove_members(user_members_removed || [], [:domain])
            a.add_members((user_members_added || []).map{ |m| Domain.to_member(m) }, [:domain])
            if a.has_member_changes?
              a.save!
            end
            a.run_jobs
          end
        end
      end
    end
    set_state(:completed)
  end
end
