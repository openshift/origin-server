class RestApplication10 < OpenShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url,
   :building_with, :building_app, :build_job_url, :gear_profile, :scalable, :health_check_path, :scale_min, :scale_max, :cartridges

  def initialize(app, url, nolinks=false)
    self.embedded = {}
    app.requires(true).each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      if cart.categories.include? "web_framework"
        self.framework = cart.name
      else
        self.embedded[cart.name] = {info: {}}
      end
    end

    self.name = app.name
    self.creation_time = app.created_at
    self.uuid = app.uuid
    self.aliases = app.aliases
    self.gear_count = app.num_gears
    self.domain_id = app.domain.namespace

    self.gear_profile = app.default_gear_size
    self.scalable = app.scalable

    if app.scalable
      self.scale_min, self.scale_max = app.get_app_scaling_limits
    else
      self.scale_min, self.scale_max = [1, 1]
    end

    self.git_url = "ssh://#{app.ssh_uri}/~/git/#{@name}.git/"
    self.app_url = "http://#{app.fqdn}/"
    self.ssh_url = "ssh://#{app.ssh_uri}"
    self.health_check_path = app.health_check_path

    self.building_with = nil
    self.building_app = nil
    self.build_job_url = nil

    app.component_instances.each do |component_instance|
      cart = CartridgeCache::find_cartridge(component_instance.cartridge_name)
      if cart.categories.include?("ci_builder")
        self.building_with = cart.name
        self.build_job_url = component_instance.component_properties["job_url"]
        break
      end
    end

    app.domain.applications.each do |domain_app|
      domain_app.component_instances.each do |component_instance|
        cart = CartridgeCache::find_cartridge(component_instance.cartridge_name)
        if cart.categories.include?("ci")
          self.building_app = domain_app.name
          break
        end
      end
    end

    unless nolinks
      carts = CartridgeCache.find_cartridge_by_category("embedded").map{ |c| c.name }

      self.links = {
        "GET" => Link.new("Get application", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
        "GET_DESCRIPTOR" => Link.new("Get application descriptor", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/descriptor")),
        "GET_GEARS" => Link.new("Get application gears", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gears")),
        "GET_GEAR_GROUPS" => Link.new("Get application gear groups", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gear_groups")),
        "START" => Link.new("Start application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "start")
        ]),
        "STOP" => Link.new("Stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "stop")
        ]),
        "RESTART" => Link.new("Restart application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "restart")
        ]),
        "FORCE_STOP" => Link.new("Force stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "force-stop")
        ]),
        "ADD_ALIAS" => Link.new("Add application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "add-alias"),
          Param.new("alias", "string", "The server alias for the application")
        ]),
        "REMOVE_ALIAS" => Link.new("Remove application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "remove-alias"),
          Param.new("alias", "string", "The application alias to be removed")
        ]),
        "SCALE_UP" => Link.new("Scale up application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-up")
        ]),
        "SCALE_DOWN" => Link.new("Scale down application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-down")
        ]),
        "TIDY" => Link.new("Tidy the application framework", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [                                                                                                                                       
          Param.new("event", "string", "event", "tidy")                                                                                                                                                                                                                            
        ]), 
        "RELOAD" => Link.new("Reload the application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [                                                                                                                                             
          Param.new("event", "string", "event", "reload")                                                                                                                                                                                                                          
        ]),
        "THREAD_DUMP" => Link.new("Trigger thread dump", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "thread-dump")
        ]),
        "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
        "ADD_CARTRIDGE" => Link.new("Add embedded cartridge", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"),[
          Param.new("cartridge", "string", "framework-type, e.g.: mongodb-2.2", carts)
        ]),
        "LIST_CARTRIDGES" => Link.new("List embedded cartridges", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges")),
        "DNS_RESOLVABLE" => Link.new("Resolve DNS", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/dns_resolvable"))
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "application"
    super(options)
  end
end
