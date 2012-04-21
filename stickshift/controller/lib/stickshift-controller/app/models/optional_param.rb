class OptionalParam < StickShift::Model
  attr_accessor :name, :type, :description, :valid_options, :default_value
  
  def initialize(name=nil, type=nil, description=nil, valid_options=nil, default_value=nil)
    self.name = name
    self.type = type
    self.description = description
    self.valid_options = valid_options || Array.new
    self.default_value = default_value
  end
end
