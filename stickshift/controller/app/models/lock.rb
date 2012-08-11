class Lock
  include Mongoid::Document
  has_and_belongs_to_many :apps, class_name: Application.name, inverse_of: nil
  belongs_to :user, class_name: CloudUser.name
  field :locked, type:Boolean

  def self.lock_user(user)
    begin
      lock = Lock.where( { user_id: user._id, locked: false, app_ids: []} ).find_and_modify( {"$set" => { user_id: user._id, locked: true, app_ids: []}}, upsert: true, new:true)
      return (lock.user == user and lock.locked)
    rescue Moped::Errors::OperationFailure
      return false
    end
  end
  
  def self.unlock_user(user)
    begin    
      lock = Lock.where( { user_id: user._id, locked: true, app_ids: []} ).find_and_modify( {"$set" => { user_id: user._id, locked: false, app_ids: []}}, upsert: true, new:false)
      return (lock.user == user and lock.locked)
    rescue Moped::Errors::OperationFailure
      return false
    end    
  end
  
  def self.lock_application(application)
    begin    
      user = application.domain.owner
      lock = Lock.where( { user_id: user._id, locked: false, :app_ids.nin => [application._id]} ).find_and_modify( {"$set" => { user_id: user._id, locked: false}, "$push"=> {app_ids: application._id}}, upsert: true, new:true)
      return (lock.user == user and !lock.locked and lock.app_ids.include?(application._id))
    rescue Moped::Errors::OperationFailure
      return false
    end      
  end
  
  def self.unlock_application(application)
    begin    
      user = application.domain.owner
      lock = Lock.where( { user_id: user._id, locked: false, :app_ids.in => [application._id]} ).find_and_modify( {"$set" => { user_id: user._id, locked: false}, "$pop"=> {app_ids: application._id}}, upsert: true, new:false)
      return (lock.user == user and !lock.locked and lock.app_ids.include?(application._id))
    rescue Moped::Errors::OperationFailure
      return false
    end
  end
end