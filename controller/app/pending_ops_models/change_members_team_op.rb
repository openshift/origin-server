class ChangeMembersTeamOp < PendingTeamOps

  field :members_added, type: Array
  field :members_removed, type: Array
  field :roles_changed, type: Array

  def execute
    from = [Team.member_type, team._id]
    Domain.accessible(team).select do |d|
      if team_role = d.role_for(team)
        d.remove_members(members_removed || [], from)
        d.add_members((members_added || []).map{ |m| Team.to_member(m).tap {|member| member.role = team_role } }, from)
        if d.has_member_changes?
          d.save!
        end
      end
    end.each do |domain|
      # only run jobs on domains that had changes
      domain.run_jobs
    end
    set_state(:completed)
  end
end
