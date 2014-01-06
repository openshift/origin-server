# Class representing a group of pending operations that must be executed in a transactional manner.
# @!attribute [r] pending_ops
#   @return [Array[PendingAppOp]] Array of pending operations that need to occur for this {Application}
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingDomainOps} operation that this operation is part of
# @!attribute [r] op_type
#   @return [Symbol] Group level operation type
# @!attribute [r] arguments
#   @return [Hash] Group level arguments hash
class PendingAppOpGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include TSort

  embedded_in :application, class_name: Application.name
  embeds_many :pending_ops, class_name: PendingAppOp.name

  field :parent_op_id, type: Moped::BSON::ObjectId
  field :num_gears_added,   type: Integer, default: 0
  field :num_gears_removed, type: Integer, default: 0
  field :num_gears_created, type: Integer, default: 0
  field :num_gears_destroyed, type: Integer, default: 0
  field :num_gears_rolled_back, type: Integer, default: 0
  field :user_agent, type: String, default: ""

  def initialize(attrs = nil, options = nil)
    parent_opid = nil
    if !attrs.nil? and attrs[:parent_op]
      parent_opid = attrs[:parent_op]._id 
      attrs.delete(:parent_op)
    end
    super
    self.parent_op_id = parent_opid 
  end

  def eligible_rollback_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    reloaded_app = Application.find_by(_id: application._id)
    op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.in => [:completed, :queued]).select{|op| (pending_ops.where(:prereq => op._id.to_s, :state.in => [:completed, :queued]).count == 0)}
  end

  def eligible_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    reloaded_app = Application.find_by(_id: application._id)
    op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.ne => :completed).select{|op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0}
  end

  def eligible_pre_execute_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    
    if application.persisted?
      reloaded_app = Application.find_by(_id: application._id)
      op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
      self.pending_ops = op_group.pending_ops
    end
    
    pending_ops.where(:state.ne => :completed, :pre_save => true).select{|op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0}
  end

  # The pre_execute method does not handle parallel executions
  # it has been created primarily to execute mongo operations
  def pre_execute(result_io=nil)
    result_io = ResultIO.new if result_io.nil?
    begin
      while(pending_ops.where(:state.ne => :completed, :pre_save => true).count > 0) do
        Rails.logger.debug "Pre-Executing ops..."
        eligible_pre_execute_ops.each do|op|
          Rails.logger.debug "Pre-Execute #{op.class.to_s}"
          # set the pending_op state to queued
          op.set_state(:queued) 
          return_val = op.execute
          result_io.append return_val if return_val.is_a? ResultIO
          op.set_state(:completed)
        end
      end
    end
  end

  def execute(result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    begin
      while(pending_ops.where(:state.ne => :completed).count > 0) do
        handle = RemoteJob.create_parallel_job
        parallel_job_ops = []

        eligible_ops.each do|op|
          Rails.logger.debug "Execute #{op.class.to_s}"

          # set the pending_op state to queued
          op.set_state(:queued)


          if op.is_parallel_executable
            op.add_parallel_execute_job(handle)
            parallel_job_ops.push op
          else
            return_val = op.execute
            result_io.append return_val if return_val.is_a? ResultIO
            if result_io.exitcode != 0
              op.set_state(:failed)
              if result_io.hasUserActionableError
                raise OpenShift::UserException.new("Unable to execute #{self.class.to_s}", result_io.exitcode, nil, result_io) 
              else
                raise OpenShift::NodeException.new("Unable to execute #{self.class.to_s}", result_io.exitcode, result_io)
              end
            else
              op.set_state(:completed)
            end
          end
        end

        if parallel_job_ops.length > 0
          RemoteJob.execute_parallel_jobs(handle)
          failed_ops = []
          RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
            if tag.has_key?("expose-ports") and status == 0
              result = ResultIO.new(status, output, gear_id)
              component_instance_id = tag["expose-ports"]
              component_instance = application.component_instances.find(component_instance_id)
              component_instance.process_properties(result)
              process_gear = nil
              application.group_instances.each do |gi|
                gi.gears.each do |g|
                  if g.uuid.to_s == gear_id
                    process_gear = g
                    break
                  end
                end
                break if process_gear
              end
              application.process_commands(result, component_instance, process_gear)
            else
              result_io.append ResultIO.new(status, output, gear_id)
              failed_ops << tag["op_id"] if status != 0
            end
          end
          parallel_job_ops.each do |op|
            if failed_ops.include? op._id.to_s
              op.set_state(:failed)
            else
              op.set_state(:completed)
            end
          end
          self.application.save

          unless failed_ops.empty?
            if result_io.hasUserActionableError
              raise OpenShift::UserException.new(result_io.errorIO.string, result_io.exitcode, nil, result_io)
            else
              failures = failed_ops.map{ |op_id| parallel_job_ops.find { |p_op| p_op._id.to_s == op_id }.action_message rescue nil }.
                group_by{ |m| m }.
                values.
                map{ |arr| "#{arr[0]} on #{failed_ops.length > 1 ? "#{failed_ops.length} gears" : "1 gear"}." }
              raise OpenShift::ApplicationOperationFailed.new("#{failures.join(' ')} Please try again and contact support if the issue persists.", 1, result_io)
            end
          end
        end
      end
      unless self.parent_op_id.nil?
        reloaded_domain = Domain.find_by(_id: self.application.domain_id)
        reloaded_domain.pending_ops.find(self.parent_op_id).child_completed(self.application)
      end
    rescue Exception => e_orig
      Rails.logger.error e_orig.message
      Rails.logger.error e_orig.backtrace.inspect
      raise e_orig
    end
  end

  def execute_rollback(result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    while(pending_ops.where(:state => :completed).count > 0) do
      handle = RemoteJob.create_parallel_job
      parallel_job_ops = []

      eligible_rollback_ops.each do|op|
        Rails.logger.debug "Rollback #{op.class.to_s}"

        if op.is_parallel_executable
          op.add_parallel_rollback_job(handle)
          parallel_job_ops.push op
        else
          return_val = op.rollback
          result_io.append return_val if return_val.is_a? ResultIO
          op.set_state(:rolledback)
        end
      end

      if parallel_job_ops.length > 0
        RemoteJob.execute_parallel_jobs(handle)
        parallel_job_ops.each{ |op| op.set_state(:rolledback) }
        self.application.save
      end
    end
  end

  # Persists change operation only if the additional number of gears requested are available on the domain owner
  #
  # == Parameters:
  # num_gears::
  #   Number of gears to add or remove
  #
  # ops::
  #   Array of pending operations.
  #   @see {PendingAppOps}
  def try_reserve_gears(num_gears_added, num_gears_removed, app, ops)
    owner = app.domain.owner
    begin
      until Lock.lock_user(owner, app)
        sleep 1
      end
      owner.reload
      if owner.consumed_gears + num_gears_added > owner.max_gears and num_gears_added > 0
        raise OpenShift::GearLimitReachedException.new("#{owner.login} is currently using #{owner.consumed_gears} out of #{owner.max_gears} limit and this application requires #{num_gears_added} additional gears.")
      end
      owner.consumed_gears += num_gears_added
      self.pending_ops.push ops
      self.num_gears_added = num_gears_added
      self.num_gears_removed = num_gears_removed
      self.save if app.persisted?
      owner.save
    ensure
      Lock.unlock_user(owner, app)
    end
  end

  def unreserve_gears(num_gears_removed, app)
    return if num_gears_removed == 0
    owner = app.domain.owner
    begin
      until Lock.lock_user(owner, app)
        sleep 1
      end
      owner.reload
      owner.consumed_gears -= num_gears_removed
      owner.save
    ensure
      Lock.unlock_user(owner, app)
    end
  end

  def serializable_hash_with_timestamp
    unless self.persisted?
      if self.created_at.nil?
        self.set_created_at
      end
      if self.updated_at.nil? and self.able_to_set_updated_at?
        self.set_updated_at
      end
    end

    self.serializable_hash
  end
end
