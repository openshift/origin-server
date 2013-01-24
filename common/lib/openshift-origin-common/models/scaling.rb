module OpenShift
  class Scaling < OpenShift::Model
    attr_accessor :min, :max, :min_managed
    
    def initialize
      self.min = 1
      self.max = -1
      self.min_managed = 1
    end

    def generated
      self.min == 1 && self.max == -1 && self.min_managed = 1
    end
    
    def from_descriptor(spec_hash = {})
      self.min = spec_hash["Min"].to_i || 1
      self.max = spec_hash["Max"].to_i || -1
      self.min_managed = spec_hash["Min-Managed"].to_i || 1
      self
    end
    
    def to_descriptor
      {
        "Min" => self.min,
        "Max" => self.max,
        "Min-Managed" => self.min_managed
      }
    end
  end
end