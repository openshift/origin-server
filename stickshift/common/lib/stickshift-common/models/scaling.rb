module StickShift
  class Scaling < StickShift::UserModel
    attr_accessor :min, :max
    
    def initialize
      self.min = 1
      self.max = -1
    end
    
    def from_descriptor(spec_hash = {})
      self.min = spec_hash["Min"].to_i || 1
      self.max = spec_hash["Max"].to_i || -1
      self
    end
    
    def to_descriptor
      {
        "Min" => self.min,
        "Max" => self.max
      }
    end
  end
end