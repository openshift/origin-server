class RestApplication12 < OpenShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, 
                :ssh_url, :gear_profile, :scalable, :health_check_path, :building_with, :building_app, :build_job_url, :cartridges
  include LegacyBrokerHelper

  def initialize(app, url, nolinks=false)
    self.framework = app.framework
    self.name = app.name
    self.creation_time = app.creation_time
    self.uuid = app.uuid
    self.aliases = app.aliases || Array.new
    self.gear_count = (app.gears.nil?) ? 0 : app.gears.length
    self.embedded = app.embedded
    self.domain_id = app.domain.namespace
    self.gear_profile = app.node_profile
    self.scalable = app.scalable
    self.git_url = "ssh://#{@uuid}@#{@name}-#{@domain_id}.#{Rails.configuration.openshift[:domain_suffix]}/~/git/#{@name}.git/"
    self.app_url = "http://#{@name}-#{@domain_id}.#{Rails.configuration.openshift[:domain_suffix]}/"
    self.ssh_url = "ssh://#{@uuid}@#{@name}-#{@domain_id}.#{Rails.configuration.openshift[:domain_suffix]}"
    self.health_check_path = app.health_check_path
    self.building_with = nil
    self.building_app = nil
    self.build_job_url = nil

    app.embedded.each { |cname, cinfo|
      cart = CartridgeCache::find_cartridge(cname)
      if cart.categories.include? "ci_builder"
        self.building_with = cart.name
        self.build_job_url = cinfo["job_url"]
        break
      end
    }
    app.user.applications.each { |user_app|
      cart = CartridgeCache::find_cartridge(user_app.framework)
      if cart.categories.include? "ci"
        self.building_app = user_app.name
        break
      end
    }

    cart_type = "embedded"
    cache_key = "cart_list_#{cart_type}"
    unless nolinks
      carts = nil
      if app.scalable
        carts = Application::SCALABLE_EMBEDDED_CARTS
      else
        carts = get_cached(cache_key, :expires_in => 21600.seconds) do
          Application.get_available_cartridges("embedded")
        end
      end
      # Update carts list
      # - remove already embedded carts
      # - remove conflicting carts
      app.embedded.keys.each do |cname|
        carts -= [cname]
        cinfo = CartridgeCache.find_cartridge(cname)
        carts -= cinfo.conflicts_feature if defined?(cinfo.conflicts_feature)
      end if !app.embedded.empty?

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
        "EXPOSE_PORT" => Link.new("Expose port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "expose-port")
        ]),
        "CONCEAL_PORT" => Link.new("Conceal port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "conceal-port")
        ]),
        "SHOW_PORT" => Link.new("Show port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "show-port")
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
