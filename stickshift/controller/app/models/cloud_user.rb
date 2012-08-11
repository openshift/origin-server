class CloudUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :login, type: String
  field :capabilities, type: Hash, default: {"subaccounts" => false, "gear_sizes" => ["small"], "max_gears" => 3}
  field :parent_user_id, type: Moped::BSON::ObjectId
  field :plan_id, type: String
  field :usage_account_id, type: String
  field :consumed_gears, type: Integer, default: 0
  embeds_many :ssh_keys, class_name: SshKey.name
  embeds_many :pending_ops, class_name: PendingUserOps.name
  
  validates :login, presence: true, login: true
  validates :capabilities, presence: true, capabilities: true
  
  def auth_method=(m)
    @auth_method = m
  end
  
  def auth_method
    @auth_method
  end
  
  def max_gears
    self.capabilities["max_gears"]
  end
  
  def add_ssh_key(key)
    self.ssh_keys << key
    self.save
  end
  
  def update_ssh_key(key)
    k = self.ssh_keys.find_by(name: key.name)
    k.content = key.content
    k.type = key.type
    k.save
    return k
  end
  
  def remove_ssh_key(name)
    k = self.ssh_keys.find_by(name: name)
    self.ssh_keys.delete(k)
    self.save
  end
end
