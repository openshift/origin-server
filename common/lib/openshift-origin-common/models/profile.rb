module OpenShift
  class Profile < OpenShift::Model
    validates_presence_of :name, :groups
    attr_accessor :name, :provides, :components, :group_overrides,
                  :connections, :start_order, :stop_order, :configure_order,
                  :generated

    def initialize
      self.generated = false
      self.provides = []
      self.group_overrides = []
      self.connections = []
      self.components = []
      @_component_name_map = {}
    end

    def components=(data)
      @components = data
      @components.each {|comp| @_component_name_map[comp.name] = comp }
    end

    def get_component(comp_name)
      @_component_name_map[comp_name]
    end

    def from_descriptor(cartridge, spec_hash = {})
      self.name = spec_hash["Name"] || cartridge.name
      self.provides = spec_hash["Provides"] || []
      self.start_order = spec_hash["Start-Order"] || []
      self.stop_order = spec_hash["Stop-Order"] || []
      self.configure_order = spec_hash["Configure-Order"] || []

      #fixup user data. provides, start_order, start_order, configure_order bust be arrays
      self.provides = [self.provides] if self.provides.class == String
      self.start_order = [self.start_order] if self.start_order.class == String
      self.stop_order = [self.stop_order] if self.stop_order.class == String
      self.configure_order = [self.configure_order] if self.configure_order.class == String

      if (components = spec_hash["Components"]).is_a? Hash
        components.each do |cname, c|
         comp = Component.new.from_descriptor(self, c)
         comp.name = cname
         @components << comp
         @_component_name_map[comp.name] = comp
       end
      else
        c = Component.new.from_descriptor(self, {
          "Publishes"  => spec_hash["Publishes"], 
          "Subscribes" => spec_hash["Subscribes"], 
          "Scaling"    => spec_hash["Scaling"], 
        })
        c.generated = true
        @components << c
        @_component_name_map[c.name] = c
      end

      if (connections = spec_hash["Connections"]).is_a? Hash
        connections.each{ |n,c| self.connections << Connection.new(n).from_descriptor(c) }
      end

      self.group_overrides ||= []
      if (overrides = spec_hash["Group-Overrides"]).is_a? Array
        overrides.each{ |o| self.group_overrides << o.dup }
      end

      self
    end

    def to_descriptor
      h = {}
      h["Provides"] = @provides unless @provides.nil? || @provides.empty?
      h["Start-Order"] = @start_order unless @start_order.nil? || @start_order.empty?
      h["Stop-Order"] = @stop_order unless @stop_order.nil? || @stop_order.empty?
      h["Configure-Order"] = @configure_order unless @configure_order.nil? || @configure_order.empty?
  
      if self.components.length == 1 && self.components.first.generated
        comp_h = self.components.first.to_descriptor
        comp_h.delete("Name")
        h.merge!(comp_h)
      else
        h["Components"] = {}
        self.components.each do |v|
          h["Components"][v.name] = v.to_descriptor
        end
      end
      if !self.connections.empty?
        h["Connections"] = {}
        self.connections.each do |v|
          h["Connections"][v.name] = v.to_descriptor
        end
      end
      h["Group-Overrides"] = self.group_overrides if !self.group_overrides.empty?
      h
    end
  end
end
