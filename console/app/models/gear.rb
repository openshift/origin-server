class Gear < RestApi::Base
  schema do
    string :id, :gear_profile, :state
  end
  #custom_id :id

  belongs_to :application
  has_many :components, :class_name => as_indifferent_hash

  def state
    (super || :unknown).to_sym
  end
end
