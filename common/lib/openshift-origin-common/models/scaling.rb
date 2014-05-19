module OpenShift
  class Scaling < OpenShift::Model
    attr_accessor :min, :max, :required, :min_managed, :multiplier

    def initialize
      self.min = 1
      self.max = -1
      self.min_managed = 1
      self.multiplier = 1
      self.required = false
    end

# def multiplier
#      if self.max==1
#        return -1
#      end
#      @multiplier
#    end

    def generated
      self.min == 1 && self.max == -1 && self.min_managed == 1 && self.multiplier == 1 && self.required == false
    end

    def from_descriptor(spec_hash = {})
      self.min = (spec_hash["Min"] || 1).to_i
      self.max = (spec_hash["Max"] || -1).to_i
      self.min_managed = spec_hash["Min-Managed"].to_i || 1
      self.multiplier = spec_hash["Multiplier"].nil? ? 1 : spec_hash["Multiplier"].to_i
      self.required = spec_hash["Required"]
      self
    end

    def to_descriptor
      {
        "Min" => self.min,
        "Max" => self.max,
        "Min-Managed" => self.min_managed,
        "Multiplier" => self.multiplier,
        "Required" => self.required,
      }
    end
  end
end
