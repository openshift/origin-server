class Gear < RestApi::Base
  schema do
    string :uuid, :gear_profile
  end
  custom_id :uuid

  belongs_to :application

  def components
    @attributes[:components]
  end
end
