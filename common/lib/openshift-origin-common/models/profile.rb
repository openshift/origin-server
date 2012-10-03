module OpenShift
  class Profile < OpenShift::Model
    validates_presence_of :name, :groups
    attr_accessor :name, :provides, :component_name_map, :group_name_map, :group_overrides,
                  :connection_name_map, :property_overrides, :service_overrides,
                  :start_order, :stop_order, :configure_order, :generated
    exclude_attributes :component_name_map, :group_name_map, :connection_name_map
    include_attributes :components, :groups, :connections
    
    def initialize
      self.generated = false
      self.provides = []
      self.group_overrides = nil
    end
    
    def components=(data)
      data.each {|comp| add_component(comp)}
    end
    
    def groups=(data)
      data.each {|group| add_group(group)}
    end
    
    def connections=(data)
      data.each {|conn| add_connection(conn)}
    end
    
    def components(name=nil)
      @component_name_map = {} if @component_name_map.nil?
      if name.nil?
        @component_name_map.values
      else
        @component_name_map[name]
      end
    end
    
    def groups(name=nil)
      @group_name_map = {} if @group_name_map.nil?
      if name.nil?
        @group_name_map.values
      else
        @group_name_map[name]
      end
    end
    
    def connections(name=nil)
      @connection_name_map = {} if @connection_name_map.nil?
      if name.nil?
        @connection_name_map.values
      else
        @connection_name_map[name]
      end
    end
    
    def add_component(comp)
      component_name_map_will_change!
      @component_name_map = {} if @component_name_map.nil?
      if comp.class == Component
        @component_name_map[comp.name] = comp
      else
        key = comp["name"]
        @component_name_map[key] = Component.new(key)
        @component_name_map[key].attributes=comp
      end
    end
    
    def add_group(group)
      group_name_map_will_change!
      @group_name_map = {} if @group_name_map.nil?
      if group.class == Group
        @group_name_map[group.name] = group
      else
        key = group["name"]
        @group_name_map[key] = Group.new(key)
        @group_name_map[key].attributes=group
      end
    end
    
    def add_connection(conn)
      connection_name_map_will_change!
      @connection_name_map = {} if @connection_name_map.nil?
      if conn.class == Connection
        @connection_name_map[conn.name] = conn
      else
        key = conn["name"]
        @connection_name_map[key] = Connection.new(key)
        @connection_name_map[key].attributes=conn
      end
    end

    def from_descriptor(spec_hash = {})
      self.name = spec_hash["Name"] || "default"
      self.provides = spec_hash["Provides"] || []
      self.start_order = spec_hash["Start-Order"] || []
      self.stop_order = spec_hash["Stop-Order"] || []
      self.configure_order = spec_hash["Configure-Order"] || []
      
      #fixup user data. provides, start_order, start_order, configure_order bust be arrays
      self.provides = [self.provides] if self.provides.class == String
      self.start_order = [self.start_order] if self.start_order.class == String
      self.stop_order = [self.stop_order] if self.stop_order.class == String
      self.configure_order = [self.configure_order] if self.configure_order.class == String
      
      if spec_hash.has_key?("Components")
        spec_hash["Components"].each do |cname, c|
         comp = Component.new.from_descriptor(c)
         comp.name = cname
         add_component(comp)
       end
      else
        comp_spec_hash = spec_hash.dup.delete_if{|k,v| !["Publishes", "Subscribes"].include?(k) }
        c = Component.new.from_descriptor(comp_spec_hash)
        c.generated = true
        add_component(c)
      end
      
      if spec_hash.has_key?("Groups")
        spec_hash["Groups"].each do |gname, g|
          group = Group.new.from_descriptor(g)
          group.name = gname
          add_group(group)
        end
      else
        group = Group.new
        self.components.each do |c|
          group.add_component_ref(ComponentRef.new(c.name).from_descriptor(c.name))
        end
        if spec_hash.has_key?("Scaling")
          group.scaling = Scaling.new.from_descriptor(spec_hash["Scaling"])
        end
        group.generated = true
        add_group(group)
      end
      
      if spec_hash.has_key?("Connections")
        spec_hash["Connections"].each do |n,c|
          conn = Connection.new(n).from_descriptor(c)
          add_connection(conn)
        end
      end

      self.group_overrides = [] if self.group_overrides.nil?
      if spec_hash.has_key?("GroupOverrides")
        spec_hash["GroupOverrides"].each do |go|
          # each group override is a list
          group_overrides << go.dup
        end
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
      
      if self.groups.length == 1 && self.groups.first.generated
        h["Scaling"] = self.groups.first.scaling.to_descriptor if !self.groups.first.scaling.generated
      else
        h["Groups"] = {}
        self.groups.each do |v|
          h["Groups"][v.name] = v.to_descriptor
        end
      end
      if !self.connections.empty?
        h["Connections"] = {}
        self.connections.each do |v|
          h["Connections"][v.name] = v.to_descriptor
        end
      end
      h
    end
  end
end
