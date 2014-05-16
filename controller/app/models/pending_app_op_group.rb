# Class representing a group of pending operations that must be executed in a transactional manner.
# @!attribute [r] pending_ops
#   @return [Array[PendingAppOp]] Array of pending operations that need to occur for this {Application}
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingDomainOps} operation that this operation is part of
# @!attribute [r] arguments
#   @return [Hash] Group level arguments hash
class PendingAppOpGroup
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include TSort

  embedded_in :application, class_name: Application.name
  embeds_many :pending_ops, class_name: PendingAppOp.name, cascade_callbacks: true

  field :parent_op_id, type: Moped::BSON::ObjectId
  field :num_gears_added,   type: Integer, default: 0
  field :num_gears_removed, type: Integer, default: 0
  field :num_gears_created, type: Integer, default: 0
  field :num_gears_destroyed, type: Integer, default: 0
  field :num_gears_rolled_back, type: Integer, default: 0
  field :user_agent, type: String, default: ""
  field :rollback_blocked, type: Boolean, default: false

  belongs_to :job_state, class_name: JobState.name, inverse_of: nil

  def initialize(attrs = nil, options = nil)
    parent_opid = nil
    if !attrs.nil? and attrs[:parent_op]
      parent_opid = attrs[:parent_op]._id 
      attrs.delete(:parent_op)
    end
    super
    self.parent_op_id = parent_opid 
  end

  def execute_ops?
    execute_ops = true
    if pending_ops.where(:state.nin => [:init, :completed]).count == 0
      pending_ops.where(:state => :init).each do |op|
        if op.execution_attempts > 0 || op.rollback_attempts > 0
          execute_ops = false
          break
        end
      end
    else
      execute_ops = false
    end
    execute_ops
  end

  def retry_ops?
    retry_ops = true
    if pending_ops.where(:state => :rolledback).count > 0
      retry_ops = false
    else
      pending_ops.where(:state.in => [:init, :queued, :failed]).each do |op|
        if op.execution_attempts >= op.max_attempts
          retry_ops = false
          break
        end
      end
    end
    retry_ops
  end

  def rollback_ops?
    if pending_ops.where(:state => :rolledback).count == 0
      rollback_ops = false
      pending_ops.where(:state.in => [:init, :queued, :failed]).each do |op|
        if op.execution_attempts >= op.max_attempts
          rollback_ops = true
          break
        end
      end
    else
      rollback_ops = true
      pending_ops.where(:state.in => [:queued, :completed, :failed]).each do |op|
        if op.rollback_attempts >= op.max_rollback_attempts
          rollback_ops = false
          break
        end
      end
    end
    rollback_ops
  end

  def reschedule_delay
    delay = 0
    pending_ops.where(:state.ne => :rolledback).each do |op|
      if op.execution_attempts > 1 || op.rollback_attempts > 1
        new_delay = op.retry_delay * [op.execution_attempts, op.rollback_attempts].max
        delay = [delay, new_delay].max 
      end
    end
    delay
  end

  def eligible_rollback_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    reloaded_app = Application.find_by(_id: application._id)
    op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.nin => [:init, :rolledback]).select{|op| (pending_ops.where(:prereq => op._id.to_s, :state.nin => [:init, :rolledback]).count == 0)}
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

    pending_ops.where(:state.ne => :completed, :pre_save => true).select{ |op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0 }
  end

  def eligible_retry_rollback_ops(rollback_ops = [])
    return [] if rollback_ops.blank?

    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    if application.persisted?
      reloaded_app = Application.find_by(_id: application._id)
      op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
      
      rollback_op_ids = rollback_ops.map(&:_id)
      rollback_ops = op_group.pending_ops.select {|op| rollback_op_ids.include?(op._id) }
    end

    rollback_ops.select! {|op| ![:init, :rolledback].include?(op.state)}
    rollback_ops.select { |o_op| rollback_ops.select{|i_op| i_op.prereq.include?(o_op._id.to_s)}.count == 0 }
  end

  def get_rollback_ops(retry_ops = [])
    attempted_ops = pending_ops.where(:state.nin => [:init, :rolledback])
    ops = retry_ops
    ops |= attempted_ops.select {|a_op| (retry_ops.map(&:_id).map(&:to_s) & a_op.prereq).count > 0 }
    ops |= attempted_ops.select {|a_op| retry_ops.map(&:retry_rollback_op).compact.include?(a_op._id) }
    ops |= get_rollback_ops(ops) if ops.count > retry_ops.count
    ops
  end

  # The pre_execute method does not handle parallel executions
  # it has been created primarily to execute mongo operations
  def pre_execute(result_io=nil)
    result_io = ResultIO.new if result_io.nil?
    while(pending_ops.where(:state.ne => :completed, :pre_save => true).count > 0) do
      Rails.logger.debug "Pre-Executing ops..."
      eligible_pre_execute_ops.each do|op|
        Rails.logger.debug "Pre-Execute #{op.to_log_s}"
        # set the pending_op state to queued
        op.set_state(:queued) 
        return_val = op.execute
        result_io.append return_val if return_val.is_a? ResultIO
        op.set_state(:completed)
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
          Rails.logger.debug "Execute #{op.to_log_s}"
          if op.is_parallel_executable
            op.add_parallel_execute_job(handle)
            parallel_job_ops.push op
          else
            handle_op_execution(op, result_io)
          end
        end

        if parallel_job_ops.length > 0
          parallel_job_ops.each { |op| op.atomic_update({"state" => :queued}, {"execution_attempts" => 1}) }

          begin
            RemoteJob.execute_parallel_jobs(handle)
          rescue Exception => ex
            parallel_job_ops.each { |op| op.atomic_update({"state" => :failed}) }
            raise ex
          end

          failed_ops = []
          RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
            op_result = ResultIO.new(status, output, gear_id)
            result_io.append(op_result)
            update_job_status(op_result)
            failed_ops << tag["op_id"] if status != 0
          end
          parallel_job_ops.each do |op|
            if failed_ops.include? op._id.to_s
              op.atomic_update({"state" => :failed})
            else
              op.atomic_update({"state" => :completed, "execution_attempts" => 0})
            end
          end
          self.application.save!

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
      Rails.logger.error e_orig.backtrace.join("\n")
      raise e_orig
    end
  end

  def execute_rollback(result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    while (pending_ops.where(:state => :completed).count > 0) do
      handle = RemoteJob.create_parallel_job
      parallel_job_ops = []

      eligible_rollback_ops.each do|op|
        Rails.logger.debug "Rollback #{op.to_log_s}"

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
        self.application.save!
      end
    end
  end

  def rollback_ops_for_retry(failed_ops=[], result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    rollback_ops = get_rollback_ops(failed_ops)
    while (eligible_rollback_ops = eligible_retry_rollback_ops(rollback_ops)).present? do
      handle = RemoteJob.create_parallel_job
      parallel_job_ops = []

      eligible_rollback_ops.each do |op|
        Rails.logger.debug "Rollback #{op.to_log_s}"

        if op.is_parallel_executable
          op.add_parallel_rollback_job(handle)
          parallel_job_ops.push op
        else
          handle_op_rollback(op, result_io)
        end
      end

      if parallel_job_ops.length > 0
        RemoteJob.execute_parallel_jobs(handle)
        parallel_job_ops.each{ |op| op.atomic_update({"state" => :rolledback}) }
        self.application.save!
      end
    end
  end

  def handle_op_execution(op, result_io)
    op.atomic_update({"state" => :queued}, {"execution_attempts" => 1})
    begin
      return_val = op.execute
      if return_val.is_a? ResultIO
        result_io.append(return_val)
        update_job_status(return_val)
      end
      if result_io.exitcode != 0
        if result_io.hasUserActionableError
          raise OpenShift::UserException.new("Unable to execute #{op.to_log_s}", result_io.exitcode, nil, result_io) 
        else
          raise OpenShift::NodeException.new("Unable to execute #{op.to_log_s}", result_io.exitcode, result_io)
        end
      else
        op.atomic_update({"state" => :completed, "execution_attempts" => 0})
      end
    rescue Exception => ex
      op.atomic_update({"state" => :failed})
      raise ex
    end
  end

  def handle_op_rollback(op, result_io)
    begin
      return_val = op.rollback
      if return_val.is_a? ResultIO
        result_io.append(return_val)
        update_job_status(return_val)
      end
      op.atomic_update({"state" => :rolledback})
    rescue Exception => ex
      op.atomic_update({"state" => :failed})
      raise ex
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
    Lock.run_in_app_user_lock(owner, app) do
      if owner.consumed_gears + num_gears_added > owner.max_gears and num_gears_added > 0
        raise OpenShift::GearLimitReachedException.new("#{owner.login} is currently using #{owner.consumed_gears} out of #{owner.max_gears} limit and this application requires #{num_gears_added} additional gears.")
      end
      owner.consumed_gears += num_gears_added
      self.num_gears_added = num_gears_added
      self.num_gears_removed = num_gears_removed
      self.pending_ops.concat(ops)
      self.save! if app.persisted?
      owner.save!
    end
  end

  def unreserve_gears(num_gears_removed, app)
    return if num_gears_removed == 0
    owner = app.domain.owner
    Lock.run_in_app_user_lock(owner, app) do
      owner.consumed_gears -= num_gears_removed
      owner.save!
    end
  end

  def add_scheduler_job
    ApplicationJob.async(:queue => "application").execute_job(self.application._id)
    find_or_create_job_state
  end

  def find_or_create_job_state
    unless self.job_state
      jstate = nil
      begin
        jstate = JobState.find_by(op_id: self._id)
      rescue Mongoid::Errors::DocumentNotFound
        jstate = JobState.new(op_id: self._id, op_type: self.class, resource_id: self.application.id,
                              resource_type: self.application.class,
                              resource_owner: self.application.owner, owner: self.application.owner)

        jstate.save
      end

      Application.where(:_id => self.application._id, "pending_op_groups._id" => self._id).update({"$set" => {"pending_op_groups.$.job_state_id" => jstate._id}})
      self.job_state = jstate
    end
    self.job_state
  end

  def update_job_status(result_io = nil)
    if result_io
      jstate = find_or_create_job_state
      jstate.append_result(result_io)
      jstate.save
    end
  end

  def update_job_completion_state(completion_state = :success)
    jstate = find_or_create_job_state
    jstate.state = :complete
    jstate.completion_state = completion_state
    jstate.save
  end

  def get_component_instance
    if spec = comp_spec
      spec.application = application
      application.component_instances.detect{ |i| i.matches_spec?(spec) }
    end
  end
end
