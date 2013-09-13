class Member < RestApi::Base
  singular_resource

  schema do
    string :id, :login, :name, :role, :type
    boolean :owner
  end

  has_many :from, :class_name => as_indifferent_hash

  validates :login, presence: true, if: "id.blank?"
  validates :role, presence: true

  def <=>(other)
    to_s <=> other.to_s
  end

  def to_s
    name || login || id
  end
end
