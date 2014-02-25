# Represents a OpenShift Team.
# @!attribute [r] name
#   @return [String] Name reserved for this team.
# @!attribute [r] owner
#   @return [CloudUser] The {CloudUser} that owns this team.
# @!attribute [r] pending_ops
#   @return [Array[PendingTeamOps]] List of {PendingTeamOps} that need to be performed on this team.
class Team
  include Mongoid::Document
  include Mongoid::Timestamps
  include AccessControllable
  include AccessControlled
  include Membership

  class Member < ::Member
  end

  field :name, type: String
  belongs_to :owner, class_name: CloudUser.name
  embeds_many :pending_ops, class_name: PendingTeamOps.name

  has_members default_role: :view
  member_as :team

  index({'owner_id' => 1, 'name' => 1}, {:unique => true})
  create_indexes

  # Invoke save! with a rescue for a duplicate exception
  #
  # == Returns:
  #   True if the domain was saved.
  def save_with_duplicate_check!
    self.save!
  rescue Moped::Errors::OperationFailure => e
    raise OpenShift::Exception.new("Team name '#{name}' is already in use. Please choose another.", 100, "id") if [11000, 11001].include?(e.details['code'])
    raise
  end

  # Hook to prevent accidental deletion of MongoID model before all related {Gear}s are removed
  before_destroy do |team|
    raise "Please call destroy_team to remove from all domains before deleting this team" if Domain.accessible(team).count > 0
  end

  def destroy_team
    Domain.accessible(self).each do |d|
      d.remove_members(self)
      d.save!
      d.run_jobs
    end
    destroy
  end

  def scopes
    nil
  end

  def inherit_membership
    [as_member]
  end

  def self.accessible_criteria(to)
    # Find all accessible domains which also have teams as members
    # Select only the members field
    # Flatten the list of members
    # Limit to members of type 'team'
    # Select ids
    # Remove duplicates
    peer_team_ids = Domain.accessible(to).and({'members.t' => Team.member_type}).only(:members).map(&:members).flatten(1).select {|m| m.type == 'team'}.map(&:_id).uniq

    # Return teams which would normally be accessible or peer teams
    self.or(super.selector, {:id.in => peer_team_ids})
  end

  def members_changed(added, removed, changed_roles)
    pending_op = ChangeMembersTeamOp.new(members_added: added.presence, members_removed: removed.presence, roles_changed: changed_roles.presence)
    self.pending_ops.push pending_op
  end


  # Runs all jobs in "init" phase and stops at the first failure.
  #
  # IMPORTANT: When changing jobs, be sure to leave old jobs runnable so that pending_ops
  #   that are inserted during a running upgrade can continue to complete.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs
    begin
      while self.pending_ops.where(state: "init").count > 0
        op = self.pending_ops.where(state: "init").first

        # store the op._id to load it later after a reload
        # this is required to prevent a reload from replacing it with another one based on position
        op_id = op._id

        # try to do an update on the pending_op state and continue ONLY if successful
        op_index = self.pending_ops.index(op)
        retval = Team.where({ "_id" => self._id, "pending_ops.#{op_index}._id" => op._id, "pending_ops.#{op_index}.state" => "init" }).update({"$set" => { "pending_ops.#{op_index}.state" => "queued" }})

        unless retval["updatedExisting"]
          self.reload
          next
        end

        op.execute

        # reloading the op reloads the domain and then incorrectly reloads (potentially)
        # the op based on its position within the pending_ops list
        # hence, reloading the domain, and then fetching the op using the op_id stored earlier
        self.reload
        op = self.pending_ops.find_by(_id: op_id)

        op.close_op
        op.delete if op.completed?
      end
      true
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise e
    end
  end

end
