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
  field :on_domain_ids, type: Array, default: []
  field :completed_domain_ids, type: Array, default: []
  field :on_completion_method, type: Symbol
  
  # List of domains that are still pending
  #
  # == Returns:
  # Array of {Domain}s
  def pending_domains
    pending_domain_ids = on_domain_ids - completed_domain_ids
    pending_domain_ids.map{ |did| Domain.find(did) }
  end
  
  # Returns true if all domains have been processed
  def completed?
    on_domain_ids.length == completed_domain_ids.length
  end
  
  def close_op
    if completed? 
      cloud_user.user.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  # Callback from {PendingDomainOps} to indicate that a domain has been processed
  def child_completed(domain)
    self.push(:completed_domain_ids, domain._id)
    if completed?
      self.set(:state, :completed)
    end
  end
end
