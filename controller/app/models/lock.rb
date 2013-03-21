# Represents a lock object for a {CloudUser} and {Application}s that it owns
# @!attribute [r] apps
#   @return List of {Application}s that are locked
# @!attribute [r] user
#   @return {CloudUser} owner of the lock
# @!attribute [r] locked
#   @return [Boolean] repesenting if the user is locked
class Lock
  include Mongoid::Document
  
  belongs_to :user, class_name: CloudUser.name
  field :locked, type: Boolean, default: false
  field :timeout, type: Integer, default: 0
  field :app_ids, type: Hash, default: {}
    
  index({:user_id => 1})
  create_indexes

  # Attempts to lock the {CloudUser}. Once locked, no other threads can obtain a lock on the {CloudUser} or any owned {Application}s.
  # This lock is denied if any of the {Application}s owned by the {CloudUser} are currently locked.
  #
  # == Parameters:
  # user::
  #   The {CloudUser} to attempt to lock
  #
  # == Returns:
  # True if the lock was successful.
  
  def self.create_lock(user)
    lock = Lock.with(consistency: :strong).find_or_create_by( :user_id => user._id )
  end
  
  def self.delete_lock(user)
    lock = Lock.delete( :user_id => user._id )
  end
 
  # Attempts to lock the {CloudUser}. 
  # NOTE: User lock is available only for user apps with application lock.
  def self.lock_user(user, app, timeout=600)
    begin
      now = Time.now.to_i
      lock = Lock.with(consistency: :strong).find_or_create_by( :user_id => user._id )
      query = {:user_id => user._id, "$or" => [{:locked => false}, {:timeout.lt => now}], "app_ids.#{app._id}" => { "$exists" => true }}
      updates = {"$set" => { locked: true, timeout: (now + timeout) }}
      lock = Lock.with(consistency: :strong).where(query).find_and_modify(updates, new: true)
      return (not lock.nil?)
    rescue Moped::Errors::OperationFailure
      return false
    end
  end
  
  # Attempts to unlock the {CloudUser}.
  #
  # == Parameters:
  # user::
  #   The {CloudUser} to attempt to unlock
  #
  # == Returns:
  # True if the unlock was successful.
  def self.unlock_user(user, app)
    begin
      query = {:user_id => user._id, :locked => true, "app_ids.#{app._id}" => { "$exists" => true }}
      updates = {"$set" => { "locked" => false }}
      lock = Lock.with(consistency: :strong).where(query).find_and_modify(updates, new: true)
      return (not lock.nil?)
    rescue Moped::Errors::OperationFailure
      return false
    end
  end
  
  # Attempts to lock an {Application}. Once locked, no other threads can obtain a lock on the {Application} or the {CloudUser} that owns it.
  # This lock is denied if the owning {CloudUser} is locked or the {Application} has been locked by another thread.
  #
  # == Parameters:
  # application::
  #   The {Application} to attempt to lock
  #
  # == Returns:
  # True if the lock was successful.
  def self.lock_application(application, timeout=600)
    begin
      # application.domain can be nil if the application is being created immediately after domain creation
      # If the domain is being read from the secondary, it may not be present
      # If domain is nil, try to load the domain from the primary
      # Note: If there is a way to load the domain relationship from the primary, we should do that 
      if application.domain.nil?
        user_id = Domain.with(consistency: :strong).find_by(_id: application.domain_id).owner_id
      else
        user_id = application.domain.owner_id
      end
      
      app_id = application._id.to_s
      now = Time.now.to_i
      query = { :user_id => user_id, "$or" => [{"app_ids.#{app_id}" => {"$exists" => false}}, {"app_ids.#{app_id}" => {"$lt" => now}}] }
      updates = {"$set"=> { "app_ids.#{app_id}" => (now + timeout) }}
      lock = Lock.with(consistency: :strong).where(query).find_and_modify(updates, new: true)
      return (not lock.nil?)
    rescue Moped::Errors::OperationFailure => ex
      Rails.logger.error "Failed to obtain lock for application #{application.name}: #{ex.message}"
      return false
    end
  end
  
  # Attempts to unlock an {Application}.
  #
  # == Parameters:
  # application::
  #   The {Application} to attempt to unlock
  #
  # == Returns:
  # True if the unlock was successful.
  def self.unlock_application(application)
    begin
      # application.domain can be nil if the application is being created immediately after domain creation
      # If the domain is being read from the secondary, it may not be present
      # If domain is nil, try to load the domain from the primary
      # Note: If there is a way to load the domain relationship from the primary, we should do that 
      if application.domain.nil?
        user_id = Domain.with(consistency: :strong).find_by(_id: application.domain_id).owner_id
      else
        user_id = application.domain.owner_id
      end

      app_id = application._id.to_s
      query = {:user_id => user_id, :locked => false, "app_ids.#{app_id}" => { "$exists" => true }}
      updates = {"$unset"=> {"app_ids.#{app_id}" => ""}}
      lock = Lock.with(consistency: :strong).where(query).find_and_modify(updates, new: true)
      return (not lock.nil?)
    rescue Moped::Errors::OperationFailure => ex
      Rails.logger.error "Failed to unlock application #{application.name}: #{ex.message}"
      return false
    end
  end
end
