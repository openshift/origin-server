# Represents a lock object for a {CloudUser} and {Application}s that it owns
# @!attribute [r] apps
#   @return List of {Application}s that are locked
# @!attribute [r] user
#   @return {CloudUser} owner of the lock
# @!attribute [r] locked
#   @return [Boolean] representing if the user is locked
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

  def self.create_lock(user_id)
    lock = Lock.find_or_create_by( :user_id => user_id )
  end

  def self.delete_lock(user_id)
    lock = Lock.delete( :user_id => user_id )
  end

  def self.run_in_user_lock(user, timeout=15, &block)
    Lock._run_in_app_user_lock(user, nil, timeout, &block)
  end

  def self.run_in_app_user_lock(user, app, timeout=15, &block)
    raise OpenShift::UserException.new("Invalid application object.") unless app.is_a?(Application)
    Lock._run_in_app_user_lock(user, app, timeout, &block)
  end

  def self.run_in_app_lock(application, &block)
    got_lock = false
    num_retries = 10
    wait = 5
    while(num_retries > 0 and !got_lock)
      if(Lock.lock_app(application))
        got_lock = true
      else
        num_retries -= 1
        sleep(wait)
      end
    end
    if got_lock
      begin
        # reload the application to reflect any changes made by any previous operation holding the lock 
        application.reload if application.persisted?
        block.arity == 1 ? block.call(application) : yield
      ensure
        Lock.unlock_app(application)
      end
    else
      raise OpenShift::LockUnavailableException.new("Unable to perform action on app object. Another operation is already running.", 171)
    end
  end

  # IMPORTANT: class methods are not protected by 'protected' keyword below. This is added just for readability.
  #            Look at end of the class/file that actually changes some of the class methods ACLs to protected. 
  protected

  def self._run_in_app_user_lock(user, app, timeout, &block)
    got_lock = false
    num_retries = 5
    wait = 2
    app_id = (app.nil? ? nil : app.id)
    while(num_retries > 0 and !got_lock)
      if(Lock.lock_user(user.id, app_id, timeout))
        got_lock = true
      else
        num_retries -= 1
        sleep(wait)
      end
    end
    if got_lock
      begin
        # reload the user to reflect any changes made by any previous operation holding the lock 
        user.reload if user.persisted?
        block.arity == 1 ? block.call(user) : yield
      ensure
        Lock.unlock_user(user.id, app_id)
      end
    else
      raise OpenShift::LockUnavailableException.new("Unable to perform action on user object. Another operation is already running.", 171)
    end
  end

  # Attempts to lock the {CloudUser}. 
  # IMPORTANT: User lock is available only for user and for user apps with application lock.
  def self.lock_user(user_id, app_id=nil, timeout=1800)
    begin
      now = Time.now.to_i  # epoch time
      lock = Lock.find_or_create_by( :user_id => user_id )
      query = {:user_id => user_id, "$or" => [{:locked => false}, {"timeout" => {"$lt" => now}}]}
      if app_id
        query["app_ids.#{app_id}"] = { "$exists" => true }
      end
      updates = {"$set" => { locked: true, timeout: (now + timeout) }}
      lock = Lock.where(query).find_and_modify(updates, new: true)
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
  def self.unlock_user(user_id, app_id=nil)
    begin
      query = {:user_id => user_id, :locked => true}
      if app_id
        query["app_ids.#{app_id}"] = { "$exists" => true }
      end
      updates = {"$set" => { "locked" => false }}
      lock = Lock.where(query).find_and_modify(updates, new: true)
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
  def self.lock_app(application, timeout=1800)
    begin
      # application.domain can be nil if the application is being created immediately after domain creation
      # If the domain is being read from the secondary, it may not be present
      # If domain is nil, try to load the domain from the primary
      # Note: If there is a way to load the domain relationship from the primary, we should do that 
      if application.owner_id.present?
        user_id = application.owner_id
      elsif application.domain.nil?
        user_id = Domain.find_by(_id: application.domain_id).owner_id
      else
        user_id = application.domain.owner_id
      end

      app_id = application._id.to_s
      now = Time.now.to_i  # epoch time
      query = { :user_id => user_id, "$or" => [{"app_ids.#{app_id}" => {"$exists" => false}}, {"app_ids.#{app_id}" => {"$lt" => now}}] }
      updates = {"$set"=> { "app_ids.#{app_id}" => (now + timeout) }}
      lock = Lock.where(query).find_and_modify(updates, new: true)
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
  def self.unlock_app(application)
    begin
      # application.domain can be nil if the application is being created immediately after domain creation
      # If the domain is being read from the secondary, it may not be present
      # If domain is nil, try to load the domain from the primary
      # Note: If there is a way to load the domain relationship from the primary, we should do that 
      if application.owner_id.present?
        user_id = application.owner_id
      elsif application.domain.nil?
        user_id = Domain.find_by(_id: application.domain_id).owner_id
      else
        user_id = application.domain.owner_id
      end

      app_id = application._id.to_s
      query = {:user_id => user_id, "app_ids.#{app_id}" => { "$exists" => true }}
      updates = {"$unset"=> {"app_ids.#{app_id}" => ""}}
      lock = Lock.where(query).find_and_modify(updates, new: true)
      return (not lock.nil?)
    rescue Moped::Errors::OperationFailure => ex
      Rails.logger.error "Failed to unlock application #{application.name}: #{ex.message}"
      return false
    end
  end

  # This will change the given class methods ACLs to 'protected'
  class<<self;self;end.send :protected, :_run_in_app_user_lock, :lock_user, :unlock_user, :lock_app, :unlock_app

end
