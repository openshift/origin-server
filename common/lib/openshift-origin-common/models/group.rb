module OpenShift
  class Group < OpenShift::Model
    attr_accessor :name, :component_ref_name_map, :scaling, :generated
    exclude_attributes :component_ref_name_map
    include_attributes :component_refs
    
    def initialize(name="default")
      self.name = name
      self.scaling = Scaling.new
      self.generated = false
    end
    
    def component_refs=(data)
      data.each do |value|
        add_component_ref(value)
      end
    end
    
    def component_refs(name=nil)
      @component_ref_name_map = {} if @component_ref_name_map.nil?
      if name.nil?
        @component_ref_name_map.values
      else
        @component_ref_name_map[name]
      end
    end
    
    def add_component_ref(component_ref)
      component_ref_name_map_will_change!
      component_refs_will_change!
      @component_ref_name_map = {} if @component_ref_name_map.nil?
      if component_ref.class == ComponentRef
        @component_ref_name_map[component_ref.name] = component_ref
      else
        key = component_ref["name"]            
        @component_ref_name_map[key] = ComponentRef.new
        @component_ref_name_map[key].attributes=component_ref
      end
    end
    
    def scaling=(value)
      scaling_will_change!
      if value.kind_of?(Hash)
        @scaling = Scaling.new
        @scaling.attributes=value
      else
        @scaling = value
      end
    end
    
    def from_descriptor(spec_hash = {})
      self.name = spec_hash["Name"] || "default"
      if spec_hash.has_key?("Components")
        spec_hash["Components"].each do |n,c|
          self.add_component_ref(ComponentRef.new(n).from_descriptor(c))
        end
      end
      self.scaling.from_descriptor spec_hash["Scaling"] if spec_hash.has_key?("Scaling")
      self
    end
    
    def to_descriptor
      components = {}
      self.component_refs.each do |c|
        components[c.name] = c.to_descriptor
      end

      {
        "Components" => components,
        "Scaling" => self.scaling.to_descriptor
      }
    end

    def get_name_prefix
      return "" if self.generated
      return "/group-" + self.name
    end
  end
end
