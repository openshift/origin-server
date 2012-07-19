class Param < StickShift::Model
  attr_accessor :name, :type, :description, :valid_options
  
  def initialize(name=nil, type=nil, description=nil, valid_options=nil)
    self.name = name
    self.type = type
    self.description = description
    valid_options = [valid_options] unless valid_options.kind_of?(Array)
    self.valid_options = valid_options || Array.new
  end
end
