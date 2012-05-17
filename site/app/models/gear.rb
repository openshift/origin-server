class Gear < RestApi::Base
  schema do
    string :id, :gear_profile, :state
  end
  #custom_id :id

  belongs_to :application

  def state
    (super || :unknown).to_sym
  end

  def components
    @attributes[:components]
  end
end
