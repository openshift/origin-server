class Member < RestApi::Base
  schema do
    string :id, :login, :name, :role, :type
    boolean :owner
  end  

  belongs_to :domain

  has_many :from, :class_name => as_indifferent_hash

  def valid?
    valid = super
    
    if id.blank? and login.blank? and errors[:id].blank? and errors[:login].blank?
      errors.add(:login, 'Login is required')
      valid = false
    end

    if role.blank?
      errors.add(:role, 'Role is required')
      valid = false
    end

    valid
  end

  def <=>(other)
    if other.is_a? Member
      (name || login || id) <=> (other.name || other.login || other.id)
    else
      to_s <=> other.to_s
    end
  end
end
