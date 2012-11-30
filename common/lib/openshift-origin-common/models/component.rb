module OpenShift
  class Component < OpenShift::Model
    attr_accessor :name, :publishes, :subscribes, :scaling, :generated
    
    def initialize(name=nil)
      self.name = name
      @publishes = []
      @subscribes = []
      self.scaling = Scaling.new
      self.generated = false
    end
    
    def is_singleton?
      self.scaling.max == 1
    end
    
    def from_descriptor(profile, spec_hash = {})
      self.name = spec_hash["Name"] || profile.name
      if spec_hash["Publishes"]
        spec_hash["Publishes"].each do |n, p|
          conn = Connector.new(n).from_descriptor(p)
          @publishes << conn
        end
      end
      
      if spec_hash["Subscribes"]
        spec_hash["Subscribes"].each do |n,p|
          conn = Connector.new(n).from_descriptor(p)
          @subscribes << conn
        end
      end
      
      self.scaling = Scaling.new.from_descriptor spec_hash["Scaling"] if spec_hash.has_key?("Scaling")      
      self
    end
    
    def to_descriptor
      p = {}
      self.publishes.each do |v|
        p[v.name] = v.to_descriptor
      end
      
      s = {}
      self.subscribes.each do |v|
        s[v.name] = v.to_descriptor
      end
      
      h = {}
      h["Publishes"] = p if self.publishes && !self.publishes.empty?
      h["Subscribes"] = s if self.subscribes && !self.subscribes.empty?
      h["Scaling"] = self.scaling.to_descriptor if self.scaling && !self.scaling.generated
      h
    end
  end
end