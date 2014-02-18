# Class representing a group of pending operations that must be executed in a transactional manner.
# @!attribute [r] pending_ops
#   @return [Array[PendingUserOp]] Array of pending operations that need to occur for this {User}
class PendingUserOpGroup
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include TSort

  embedded_in :cloud_user, class_name: CloudUser.name
  embeds_many :pending_ops, class_name: PendingUserOp.name, cascade_callbacks: true

  def eligible_rollback_ops
    # reloading the op_group reloads the user and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the user, and then fetching the op_group using the _id
    reloaded_user = CloudUser.find_by(_id: cloud_user._id)
    op_group = reloaded_user.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.in => [:completed, :queued]).select{|op| (pending_ops.where(:prereq => op._id.to_s, :state.in => [:completed, :queued]).count == 0)}
  end

  def eligible_ops
    # reloading the op_group reloads the user and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the user, and then fetching the op_group using the _id
    reloaded_user = CloudUser.find_by(_id: cloud_user._id)
    op_group = reloaded_user.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.ne => :completed).select{|op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0}
  end

  def execute(result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    begin
      while(pending_ops.where(:state.ne => :completed).count > 0) do

        eligible_ops.each do|op|
          Rails.logger.debug "Execute #{op.to_log_s}"

          # set the pending_op state to queued
          op.set_state(:queued)

          return_val = op.execute
          result_io.append return_val if return_val.is_a? ResultIO
          if result_io.exitcode != 0
            if result_io.hasUserActionableError
              raise OpenShift::UserException.new("Unable to execute #{op.to_log_s}", result_io.exitcode, nil, result_io) 
            else
              raise OpenShift::NodeException.new("Unable to execute #{op.to_log_s}", result_io.exitcode, result_io)
            end
          else
            op.set_state(:completed)
          end
        end

      end
    rescue Exception => e_orig
      Rails.logger.error e_orig.message
      Rails.logger.error e_orig.backtrace.join("\n")
      raise e_orig
    end
  end

  def execute_rollback(result_io=nil)
    result_io = ResultIO.new if result_io.nil?

    while(pending_ops.where(:state => :completed).count > 0) do

      eligible_rollback_ops.each do|op|
        Rails.logger.debug "Rollback #{op.to_log_s}"

        return_val = op.rollback
        result_io.append return_val if return_val.is_a? ResultIO
        op.set_state(:rolledback)
      end

    end
  end

end
