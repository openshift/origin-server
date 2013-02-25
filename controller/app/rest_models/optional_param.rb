# @!attribute [r] name
#   @return [String] Parameter name
# @!attribute [r] type
#   @return [String] Parameter type
# @!attribute [r] description
#   @return [String] Parameter desctiption
# @!attribute [r] valid_options
#   @return [Array[String]] List of valid options
# @!attribute [r] default_value
#   @return [String] Default option value
class OptionalParam < OpenShift::Model
  attr_accessor :name, :type, :description, :valid_options, :default_value
  
  def initialize(name=nil, type=nil, description=nil, valid_options=nil, default_value=nil)
    self.name = name
    self.type = type
    self.description = description
    self.valid_options = Array(valid_options)
    self.default_value = default_value
  end
end
