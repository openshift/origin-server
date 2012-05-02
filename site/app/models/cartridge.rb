#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  schema do
    string :name, 'type'
  end
  custom_id :name

  belongs_to :application

  def type
    @attributes[:type]
  end

  def type=(type)
    @attributes[:type]=type
  end
end
