module OpenShift
  class Connection < OpenShift::Model
    attr_accessor :name, :components

    def initialize(name)
      self.name = name
    end

    def from_descriptor(spec_hash = {})
      self.components = spec_hash["Components"]
      self
    end

    def to_descriptor
      {
        "Components" => self.components
      }
    end
  end
end