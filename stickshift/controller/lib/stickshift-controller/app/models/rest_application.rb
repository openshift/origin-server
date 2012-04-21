class RestApplication < StickShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :links, :domain_id, :git_url, :app_url, :gear_profile, :scalable, :health_check_path
  include LegacyBrokerHelper
  
  def initialize(app, url)
    self.framework = app.framework
    self.name = app.name
    self.creation_time = app.creation_time
    self.uuid = app.uuid
    self.aliases = app.aliases || Array.new
    self.embedded = app.embedded
    self.domain_id = app.domain.namespace
    self.gear_profile = app.node_profile
    self.scalable = scalable
    self.git_url = "ssh://#{@uuid}@#{@name}-#{@domain_id}.#{Rails.configuration.ss[:domain_suffix]}/~/git/#{@name}.git/"
    self.app_url = "http://#{@name}-#{@domain_id}.#{Rails.configuration.ss[:domain_suffix]}/"
    self.health_check_path = app.health_check_path
    cart_type = "embedded"
    cache_key = "cart_list_#{cart_type}"
    carts = get_cached(cache_key, :expires_in => 21600.seconds) do
      Application.get_available_cartridges("embedded")
    end

    self.links = {
      "GET" => Link.new("Get application", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
      "GET_DESCRIPTOR" => Link.new("Get application descriptor", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/descriptor")),      
      "GET_GEARS" => Link.new("Get application gears", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gears")),      
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
      "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
      
      "ADD_CARTRIDGE" => Link.new("Add embedded cartridge", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"),[
        Param.new("cartridge", "string", "framework-type, e.g.: mysql-5.1", carts)
      ]),
      "LIST_CARTRIDGES" => Link.new("List embedded cartridges", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"))
    }
  end
  
  def to_xml(options={})
    options[:tag_name] = "application"
    super(options)
  end
end
