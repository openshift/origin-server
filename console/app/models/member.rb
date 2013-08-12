class Member < RestApi::Base
  schema do
    string :id, :type
    boolean :owner
  end  

  has_many :from, :class_name => as_indifferent_hash
end