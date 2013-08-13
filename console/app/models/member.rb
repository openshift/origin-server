class Member < RestApi::Base
  schema do
    string :id, :name, :role, :type
    boolean :owner
  end  

  has_many :from, :class_name => as_indifferent_hash
end
