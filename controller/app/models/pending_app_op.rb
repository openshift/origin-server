# Class to represent pending operations that need to occur for the {Application}
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] retry_count
#   @return [Integer] Number of times this operation has been attempted
class PendingAppOp
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  embedded_in :pending_app_op_group, class_name: PendingAppOpGroup.name
  field :state,             type: Symbol,   default: :init
  field :prereq,            type: Array
  field :retry_count,       type: Integer,  default: 0
  field :retry_rollback_op, type: Moped::BSON::ObjectId
  field :skip_rollback,     type: Boolean

  def prereq
    self.attributes["prereq"] || []
  end

  # Sets the [PendingDomainOps] Domain level operation that spawned this operation.
  #
  # == Parameters:
  # op::
  #   The {PendingDomainOps} object.
  def parent_op=(op)
    self.parent_op_id = op._id unless op.nil?
  end

  # @return [PendingDomainOps] Domain level operation that spawned this operation.  
  def parent_op
    self.application.domain.pending_ops.find(self.parent_op_id) unless parent_op_id.nil?
  end

  # Marks the operation as completed on the parent operation.
  def completed
    set_state(:completed)
    parent_op.child_completed(application) unless parent_op_id.nil?
  end

  # this method needs to be implemented by the subclass
  def execute
    Rails.logger.debug "Execution not implemented: #{self.class.to_s}"
  end

  # this method needs to be implemented by the subclass
  def rollback
    Rails.logger.debug "Rollback not implemented: #{self.class.to_s}"
  end

  def is_parallel_executable
    return false
  end

  def add_parallel_execute_job(handle)
    Rails.logger.debug "Parallel execute not implemented: #{self.class.to_s}"
  end

  def add_parallel_rollback_job(handle)
    Rails.logger.debug "Parallel rollback not implemented: #{self.class.to_s}"
  end

  # the new_state needs to be a symbol
  def set_state(new_state)
    # in order to facilitate execution of pre-save ops, 
    # we check whether the application is persisted to mongo
    if pending_app_op_group.application.persisted?
      failure_message = "Failed to set pending_op #{self._id.to_s} state to #{new_state.to_s} for application #{self.pending_app_op_group.application.name}"
      updated_op = update_with_retries(5, failure_message) do |current_app, current_op_group, current_op, op_group_index, op_index|
        Application.where({ "_id" => current_app._id, "pending_op_groups.#{op_group_index}._id" => current_op_group._id, "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}._id" => current_op._id }).update({"$set" => { "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}.state" => new_state }})
      end
      # set the state in the object in mongoid memory for access by the caller
      self.state = updated_op.state
    else
      self.state = new_state
    end
  end

  def update_with_retries(num_retries, failure_message, &block)
    retries = 0
    success = false

    current_op = self
    current_op_group = self.pending_app_op_group
    current_app = self.pending_app_op_group.application

    # find the index and do an atomic update
    op_group_index = current_app.pending_op_groups.index(current_op_group)
    op_index = current_app.pending_op_groups[op_group_index].pending_ops.index(current_op)

    while retries < num_retries
      retval = block.call(current_app, current_op_group, current_op, op_group_index, op_index)
      if retval["updatedExisting"]
        success = true
        break
      end

      # the op needs to be reloaded to find the updated index
      current_app = Application.find_by(_id: current_app._id)
      current_op_group = current_app.pending_op_groups.find_by(_id: current_op_group._id)
      op_group_index = current_app.pending_op_groups.index(current_op_group)
      current_op = current_app.pending_op_groups[op_group_index].pending_ops.find_by(_id: current_op._id)
      op_index = current_app.pending_op_groups[op_group_index].pending_ops.index(current_op)
      retries += 1
    end

    # log the details in case we cannot update the pending_op
    unless success
      Rails.logger.error(failure_message)
    end

    return current_op
  end

  def application
    pending_app_op_group.application
  end

  def get_group_instance
    application.group_instances.find(group_instance_id)
  end

  def get_gear
    application.gears.find(gear_id)
  end

  def get_component_instance
    if spec = comp_spec
      spec.application = application
      application.component_instances.detect{ |i| i.matches_spec?(spec) }
    end
  end

  def is_app_delete_op_group?
    if pending_app_op_group.nil?
      return false
    else
      return (pending_app_op_group.kind_of?(RemoveFeaturesOpGroup) and pending_app_op_group.remove_all_features)
    end
  end

  # any child op that does not require connections to be re-executed
  # should override this method and return false
  def reexecute_connections?
    return true
  end

  def if_not_found(e)
    raise e unless Mongoid::Errors::DocumentNotFound === e
  end

  def action_message
    "#{self.class.to_s} failed"
  end

  def to_log_s
    "#{self.class} #{to_important_args.map{ |k,v| "#{k}=#{v}" }.join(' ')}"
  end

  protected
    def to_important_args
      [:comp_spec, :comp_specs, :gear_id, :group_instance_id].inject({}) do |h, sym|
        if self.respond_to?(sym)
          v = self.send(sym)
          h[sym] = to_important_args_type(v)
        end
        h
      end
    end

    def to_important_args_type(v)
      case v
      when Array then "[#{v.map{ |s| to_important_args_type(s) }.join(', ')}]"
      when ComponentSpec then "component:#{[v.name, v.cartridge_name, v.id].join("/")}"
      when NilClass then 'nil'
      else v
      end
    end
end
