module OpenShift
  class ComponentRef < OpenShift::Model
    attr_accessor :name, :component
    
    def initialize(name=nil)
      self.name = name
    end
    
    def from_descriptor(spec_hash)
      self.component = spec_hash
      self
    end
    
    def to_descriptor
      self.component
    end

    def get_name_prefix(profile)
      comp_obj = profile.components(self.component)
      return "" if comp_obj.generated
      return "/comp-" + self.name 
    end
  end
end
