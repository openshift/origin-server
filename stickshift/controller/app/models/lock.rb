# Represents a lock object for a {CloudUser} and {Application}s that it owns
# @!attribute [r] apps
#   @return List of {Application}s that are locked
# @!attribute [r] user
#   @return {CloudUser} owner of the lock
# @!attribute [r] locked
#   @return [Boolean] repesenting if the user is locked
class Lock
  include Mongoid::Document
  
  has_and_belongs_to_many :apps, class_name: Application.name, inverse_of: nil
  belongs_to :user, class_name: CloudUser.name
  field :locked, type:Boolean

  # Attempts to lock the {CloudUser}. Once locked, no other threads can obtain a lock on the {CloudUser} or any owned {Application}s.
  # This lock is denied if any of the {Application}s owned by the {CloudUser} are currently locked.
  #
  # == Parameters:
  # user::
  #   The {CloudUser} to attempt to lock
  #
  # == Returns:
  # True if the lock was succesful.
  def self.lock_user(user)
    begin
      lock = Lock.where( { user_id: user._id, locked: false, app_ids: []} ).find_and_modify( {"$set" => { user_id: user._id, locked: true, app_ids: []}}, upsert: true, new:true)
      return (lock.user == user and lock.locked)
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
  # True if the unlock was succesful.
  def self.unlock_user(user)
    begin    
      lock = Lock.where( { user_id: user._id, locked: true, app_ids: []} ).find_and_modify( {"$set" => { user_id: user._id, locked: false, app_ids: []}}, upsert: true, new:false)
      return (lock.user == user and lock.locked)
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
  # True if the lock was succesful.
  def self.lock_application(application)
    begin    
      user_id = application.domain.owner_id
      lock = Lock.where( { user_id: user_id, locked: false, :app_ids.ne => application._id} ).find_and_modify( {"$set" => { user_id: user_id, locked: false}, "$push"=> {app_ids: application._id}}, upsert: true, new:true)
      return (lock.user_id == user_id and !lock.locked and lock.app_ids.include?(application._id))
    rescue Moped::Errors::OperationFailure
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
  # True if the unlock was succesful.
  def self.unlock_application(application)
    begin    
      user_id = application.domain.owner_id
      lock = Lock.where( { user_id: user_id, locked: false, app_ids: application._id} ).find_and_modify( {"$set" => { user_id: user_id, locked: false}, "$pop"=> {app_ids: application._id}}, upsert: true, new:false)
      return (lock.user_id == user_id and !lock.locked and lock.app_ids.include?(application._id))
    rescue Moped::Errors::OperationFailure
      return false
    end
  end
end