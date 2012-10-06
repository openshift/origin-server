class RestCartridge11 < OpenShift::Model
  attr_accessor :type, :name, :version, :display_name, :description, :license, :license_url,
                :tags, :website, :help_topics, :links, :properties, :status_messages,
                :current_scale, :scales_with, :scales_from, :scales_to, :base_gear_storage, :additional_gear_storage
  
  def initialize(type, name, app, url, status_messages, nolinks=false)
    self.name = name
    self.type = type
    self.scales_from = nil
    self.scales_to = nil
    self.scales_with = nil
    self.status_messages = status_messages
    prop_values = nil
    cart = CartridgeCache.find_cartridge(name)
    if app
      if CartridgeCache.cartridge_names('standalone').include? name
        app.comp_instance_map.each { |cname, cinst|
          next if cinst.parent_cart_name!=name
          prop_values = cinst.cart_properties
          break
        }
      else
        prop_values = app.embedded[name] 
      end
      app.group_instance_map.each { |gi_name,gi|
        ci = gi.component_instances.find { |ci_name| 
          cinst = app.comp_instance_map[ci_name]
          cinst.parent_cart_name==name 
        }
        if ci
          set_scaling_info(app.comp_instance_map[ci], gi, cart)
          break
        end
      }
    else
      set_scaling_info(nil, nil, cart)
    end
    self.version = cart.version
    self.display_name = cart.display_name
    self.description = cart.description
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


  def set_scaling_info(comp_instance, group_instance, cartridge)
    if group_instance and comp_instance
      app = group_instance.app
      self.current_scale = group_instance.gears.length
      if self.scales_with.nil?
        app.embedded.each { |cart_name, cart_info|
          cart = CartridgeCache::find_cartridge(cart_name)
          if cart.categories.include? "scales"
            self.scales_with = cart.name
            break
          end
        }
      end
      if self.scales_from.nil?
        self.scales_from = group_instance.min
      else
        self.scales_from = (self.scales_from < group_instance.min) ? group_instance.min : self.scales_from
      end
      if self.scales_to.nil?
        self.scales_to = group_instance.max
      else
        self.scales_to = (self.scales_to < group_instance.max) ? group_instance.max : self.scales_to
      end
      self.base_gear_storage = group_instance.get_cached_min_storage_in_gb
      self.additional_gear_storage = comp_instance.addtl_fs_gb
    else
      prof = cartridge.profiles(cartridge.default_profile)
      group = prof.groups()[0]
      self.current_scale = 0
      self.scales_with = "haproxy_1.4"
      self.scales_from = group.scaling.min
      self.scales_to = group.scaling.max
    end
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
