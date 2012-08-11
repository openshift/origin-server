class RestCartridge11 < StickShift::Model
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website,
  :help_topics, :links, :properties
  
  def initialize(type, cart, app, url, nolinks=false)
    self.name = cart.name
    self.type = type
  
    prop_values = nil
    if app
      if cart.categories.include? "web_framework"
        app.comp_instance_map.each { |cname, cinst|
          next if cinst.parent_cart_name!=name
          prop_values = cinst.cart_properties
          break
        }
      else
        prop_values = app.embedded[name] 
      end
    end
    self.version = cart.version
    self.license = cart.license
    self.license_url = cart.license_url
    self.tags = cart.categories
    self.website = cart.website
    # self.suggests = cart.suggests_feature
    # self.requires = cart.requires_feature
    # self.depends = cart.profiles.map { |p| p.components.map { |c| c.depends_service }.flatten }.flatten.uniq
    # self.conflicts = cart.conflicts_feature
    self.help_topics = cart.help_topics
    
    self.properties = []
    cart.cart_data_def.each do |data_def|
      property = {}
      property["name"] = data_def["Key"]
      property["type"] = data_def["Type"]
      property["description"] = data_def["Description"]
      property["value"] = prop_values[data_def["Key"]] unless prop_values.nil? or prop_values[data_def["Key"]].nil?
      self.properties << property
    end
    
    if app and !nolinks
      domain_id = app.domain.namespace
      app_id = app.name
      if type == "embedded" and not app_id.nil? and not domain_id.nil?
        self.links = {
            "GET" => Link.new("Get embedded cartridge", "GET", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}")),
            "START" => Link.new("Start embedded cartridge", "POST", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}/events"), [
              Param.new("event", "string", "event", "start")
            ]),
            "STOP" => Link.new("Stop embedded cartridge", "POST", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}/events"), [
              Param.new("event", "string", "event", "stop")
            ]),
            "RESTART" => Link.new("Restart embedded cartridge", "POST", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}/events"), [
              Param.new("event", "string", "event", "restart")
            ]),
            "RELOAD" => Link.new("Reload embedded cartridge", "POST", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}/events"), [
              Param.new("event", "string", "event", "reload")
            ]),
            "DELETE" => Link.new("Delete embedded cartridge", "DELETE", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/cartridges/#{name}"))
          }
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
