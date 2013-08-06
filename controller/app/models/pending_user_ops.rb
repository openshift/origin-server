# Class to represent pending operations that need to occur for the {CloudUser}
# @!attribute [r] cloud_user
#   @return [CloudUser] The {CloudUser} that operation needs to be applied on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type.
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] arguments
#   @return [Hash] Arguments hash
# @!attribute [r] on_domain_ids
#   @return [Array] Ids for domains on which this operation needs to be run
# @!attribute [r] completed_domain_ids
#   @return [Array] Ids for domains on which this operation has been completed
# @!attribute [r] on_completion_method
#   @return [Symbol] Optional method to call on the User object after operation has completed
class PendingUserOps
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :cloud_user, class_name: CloudUser.name
  field :op_type,   type: Symbol
  field :state,    type: Symbol, :default => :init
  field :arguments, type: Hash, default: {}
  has_and_belongs_to_many :on_domains, class_name: Domain.name, inverse_of: nil
  has_and_belongs_to_many :completed_domains, class_name: Domain.name, inverse_of: nil
  field :on_completion_method, type: Symbol

  # List of domains that are still pending
  #
  # == Returns:
  # Array of {Domain}s
  def pending_domains
    pending_domains = on_domains - completed_domains
    pending_domains
  end

  # Returns true if all domains have been processed
  def completed?
    (self.state == :completed) || (on_domains.length == completed_domains.length)
  end

  def close_op
    if completed?
      cloud_user.user.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  # Callback from {PendingDomainOps} to indicate that a domain has been processed
  def child_completed(domain)
    retries = 0
    success = false

    # find the op index and do an atomic update
    op_index = self.cloud_user.pending_ops.index(self) 
    while retries < 5
      retval = CloudUser.where({ "_id" => self.cloud_user._id, "pending_ops.#{op_index}._id" => self._id }).update({"$addToSet" => { "pending_ops.#{op_index}.completed_domain_ids" => domain._id }})

      # the op needs to be reloaded to either set the :state or to find the updated index
      reloaded_user = CloudUser.find_by(_id: self.cloud_user._id)
      current_op = reloaded_user.pending_ops.find_by(_id: self._id)
      if retval["updatedExisting"]
        current_op.set(:state, :completed) if current_op.completed?
        success = true
        break
      else
        op_index = reloaded_user.pending_ops.index(current_op)
        retries += 1
      end
    end

    # log the details in case we cannot update the pending_op
    unless success
      Rails.logger.error "Failed to add domain #{domain._id} to the completed_domains for pending_op #{self._id} for user #{self.cloud_user.login}"
    end
  end

  def serializable_hash_with_timestamp
    s_hash = self.serializable_hash
    t = Time.zone.now
    if self.created_at.nil?
      s_hash["created_at"] = t
    end
    if self.updated_at.nil?
      s_hash["updated_at"] = t
    end
    s_hash
  end
end
