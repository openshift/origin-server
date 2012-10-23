module OpenShift
  class Component < OpenShift::Model
    attr_accessor :name, :publish_name_map, :subscribe_name_map, :generated, :depends, :depends_service
    exclude_attributes :publish_name_map, :subscribe_name_map
    include_attributes :publishes, :subscribes    
    
    def initialize(name=nil)
      self.name = name
      self.generated = false
    end
    
    def publishes=(data)
      data.each do |value|
        add_publish(value)
      end
    end
    
    def publishes(name=nil)
      @publish_name_map = {} if @publish_name_map.nil?
      if name.nil?
        @publish_name_map.values
      else
        @publish_name_map[name]
      end
    end
    
    def add_publish(publish)
      publish_name_map_will_change!
      publishes_will_change!
      @publish_name_map = {} if @publish_name_map.nil?
      if publish.class == Connector
        @publish_name_map[publish.name] = publish
      else
        key = publish["name"]            
        @publish_name_map[key] = Connector.new
        @publish_name_map[key].attributes=publish
      end
    end
    
    def subscribes=(data)
      data.each do |value|
        add_subscribe(value)
      end
    end
    
    def subscribes(name=nil)
      @subscribe_name_map = {} if @subscribe_name_map.nil?
      if name.nil?
        @subscribe_name_map.values
      else
        @subscribe_name_map[name]
      end
    end
    
    def add_subscribe(subscribe)
      subscribe_name_map_will_change!
      subscribes_will_change!
      @subscribe_name_map = {} if @subscribe_name_map.nil?
      if subscribe.class == Connector
        @subscribe_name_map[subscribe.name] = subscribe
      else        
        key = subscribe["name"]            
        @subscribe_name_map[key] = Connector.new
        @subscribe_name_map[key].attributes=subscribe
      end
    end
    
    def from_descriptor(spec_hash = {})
      self.name = spec_hash["Name"] || "default"
      if spec_hash["Publishes"]
        spec_hash["Publishes"].each do |n, p|
          conn = Connector.new(n).from_descriptor(p)
          self.add_publish(conn)
        end
      end
      
      if spec_hash["Subscribes"]
        spec_hash["Subscribes"].each do |n,p|
          conn = Connector.new(n).from_descriptor(p)
          self.add_subscribe(conn)
        end
      end
      
      self.depends = spec_hash["Dependencies"] || []
      self.depends_service = spec_hash["Service-Dependencies"] || []
      
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
      h["Dependencies"] = self.depends if self.depends && !self.depends.empty?
      h["Service-Dependencies"] = self.depends_service if self.depends_service && !self.depends_service.empty?
      h
    end
  end
end