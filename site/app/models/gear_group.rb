class GearGroup < RestApi::Base
  schema do
    string :name
  end
  custom_id :name

  belongs_to :application

  has_many :gears
  has_many :cartridges

  def gears
    @attributes[:gears]
  end
  def cartridges
    @attributes[:cartridges]
  end
end
