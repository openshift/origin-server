module OpenShift
  class Connector < OpenShift::Model
    attr_accessor :name, :type, :required

    def initialize(name=nil)
      self.name = name
    end

    def from_descriptor(spec_hash = {})
      self.type = spec_hash["Type"]
      self.required = spec_hash["Required"].to_s.downcase == "true" || false
      self
    end

    def to_descriptor
      {
        "Type" => self.type,
        "Required" => self.required
      }
    end
  end
end