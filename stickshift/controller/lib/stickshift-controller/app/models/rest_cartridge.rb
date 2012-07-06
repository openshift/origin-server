class RestCartridge < StickShift::Model
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website,
  :suggests, :help_topics, :links, :properties, :requires, :conflicts, :suggests, :depends
  
  def initialize(type, name, app, url)
    self.name = name
    self.type = type
  
    prop_values = app.embedded[name] if app
    cart = CartridgeCache.find_cartridge(name)
    self.version = cart.version
    self.license = cart.license
    self.license_url = cart.license_url
    self.tags = cart.categories
    self.website = cart.website
    self.suggests = cart.suggests_feature
    self.requires = cart.requires_feature
    self.depends = cart.profiles.map { |p| p.components.map { |c| c.depends_service }.flatten }.flatten.uniq
    self.conflicts = cart.conflicts_feature
    self.help_topics = cart.help_topics
    
    self.properties = []
    cart.cart_data_def.each do |data_def|
      property = {}
      property["name"] = data_def["Key"]
      property["type"] = data_def["Type"]
      property["Description"] = data_def["Description"]
      property["Value"] = prop_values[data_def["Key"]] unless prop_values.nil? or prop_values[data_def["Key"]].nil?
      self.properties << property
    end
    
    if app
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
