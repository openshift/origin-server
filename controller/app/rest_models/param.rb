# @!attribute [r] name
#   @return [String] Parameter name
# @!attribute [r] type
#   @return [String] Parameter type
# @!attribute [r] description
#   @return [String] Parameter desctiption
# @!attribute [r] valid_options
#   @return [Array[String]] List of valid options
# @!attribute [r] invalid_options
#   @return [Array[String]] List of options that are not valid
class Param < OpenShift::Model
  attr_accessor :name, :type, :description, :valid_options, :invalid_options
  
  def initialize(name=nil, type=nil, description=nil, valid_options=nil, invalid_options=nil)
    self.name = name
    self.type = type
    self.description = description
    self.valid_options = valid_options || Array.new
    self.valid_options = [self.valid_options] unless self.valid_options.kind_of?(Array)
    self.invalid_options = invalid_options || Array.new
    self.invalid_options = [self.invalid_options] unless self.invalid_options.kind_of?(Array)
  end
end

