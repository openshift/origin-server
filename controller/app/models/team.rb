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
  #only settable via admin script
  field :maps_to, type: String, default: nil
  belongs_to :owner, class_name: CloudUser.name
  embeds_many :pending_ops, class_name: PendingTeamOps.name

  has_members default_role: :view
  member_as :team

  validates :name,
    presence: {message: "Name is required and cannot be blank"},
    length:   {maximum: 250, minimum: 2, message: "Team name must be a minimum of 2 and maximum of 250 characters."}

  validates_uniqueness_of :maps_to, message: "There is already a team that maps to this group.", allow_nil: true

  index({'owner_id' => 1, 'name' => 1}, {:unique => true})
  create_indexes

  # Invoke save! with a rescue for a duplicate exception
  #
  # == Returns:
  #   True if the domain was saved.
  def save_with_duplicate_check!
    self.save!
  rescue Moped::Errors::OperationFailure => e
    raise OpenShift::UserException.new("Team name '#{name}' is already in use. Please choose another.", -1, "name") if [11000, 11001].include?(e.details['code'])
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
    peer_team_ids = Domain.accessible(to).and({'members.t' => Team.member_type}).map(&:members).flatten(1).select {|m| m.type == 'team'}.map(&:_id).uniq

    if (to.is_a?(CloudUser) && !to.view_global_teams)
      # Return teams which would normally be accessible or peer teams
      self.or(super.selector, {:id.in => peer_team_ids})
    else
      # Return teams which would normally be accessible, global or peer teams
      self.or(super.selector, {:id.in => peer_team_ids}, {:owner_id => nil})
    end
  end

  def members_changed(added, removed, changed_roles, parent_op)
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
    wait_ctr = 0
    begin
      while self.pending_ops.count > 0
        op = self.pending_ops.first

        # a stuck op could move to the completed state if its pending domains are deleted
        if op.completed?
          op.delete
          self.reload
          next
        end

        # store the op._id to load it later after a reload
        # this is required to prevent a reload from replacing it with another one based on position
        op_id = op._id

        # try to do an update on the pending_op state and continue ONLY if successful
        op_index = self.pending_ops.index(op)
        t_now = Time.now.to_i

        id_condition = {"_id" => self._id, "pending_ops.#{op_index}._id" => op_id}
        runnable_condition = {"$or" => [
          # The op is not yet running
          {"pending_ops.#{op_index}.state" => "init" },
          # The op is in the running state and has timed out
          { "pending_ops.#{op_index}.state" => "queued", "pending_ops.#{op_index}.queued_at" => {"$lt" => (t_now - run_jobs_queued_timeout)} }
        ]}
 
        queued_values = {"pending_ops.#{op_index}.state" => "queued", "pending_ops.#{op_index}.queued_at" => t_now}
        reset_values  = {"pending_ops.#{op_index}.state" => "init",   "pending_ops.#{op_index}.queued_at" => 0}
 
        retval = Team.where(id_condition.merge(runnable_condition)).update({"$set" => queued_values})
        if retval["updatedExisting"]
          wait_ctr = 0
        elsif wait_ctr < run_jobs_max_retries
          self.reload
          sleep run_jobs_retry_sleep
          wait_ctr += 1
          next
        else
          raise OpenShift::LockUnavailableException.new("Unable to perform action on team object. Another operation is already running.", 171)
        end

        begin
          op.execute

          # reloading the op reloads the domain and then incorrectly reloads (potentially)
          # the op based on its position within the pending_ops list
          # hence, reloading the domain, and then fetching the op using the op_id stored earlier
          self.reload
          op = self.pending_ops.find_by(_id: op_id)

          op.close_op
          op.delete if op.completed?
        rescue Exception => op_ex
          # doing this in rescue instead of ensure so that the state change happens only in case of exceptions
          Team.where(id_condition.merge(queued_values)).update({"$set" => reset_values})
          raise op_ex
        end
      end
      true
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise e
    end
  end

  def self.validation_map
    {name: -1}
  end

  def self.with_ids(ids)
    if ids.present?
      self.in(_id: ids)
    else
      []
    end
  end

  private
    def run_jobs_max_retries;    10;    end
    def run_jobs_retry_sleep;    5;     end
    def run_jobs_queued_timeout; 30*60; end

end
