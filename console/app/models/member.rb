class Member < RestApi::Base
  singular_resource

  schema do
    string :id, :login, :name, :role, :type
    boolean :owner
  end

  has_many :from, :class_name => as_indifferent_hash

  validates :login, presence: true, if: "id.blank?"
  validates :role, presence: true

  def name
    super || login
  end

  def <=>(other)
    [name, id] <=> [other.name, other.id]
  end
end
