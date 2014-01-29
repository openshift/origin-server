##
# @api REST
# Describes an Cartridge
# @version 1.0
#
# Example:
#   ```
#   <cartridge>
#     <name>mysql-5.1</name>
#     <type>embedded</type>
#     <status-messages nil="true"/>
#     <properties>
#       <connection-url>mysql://127.0.250.129:3306/</connection-url>
#       <username>foo</username>
#       <password>bar</password>
#       <database-name>baz</database-name>
#     </properties>
#     <links>
#     ...
#     </links>
#   </cartridge>
#   ```
#
# @!attribute [r] name
#   @return [String] Name of the cartridge
# @!attribute [r] type
#   @return [String] "standalone" or "embedded".
# @!attribute [r] status_messages
#   @return [Array<String>] Messages
# @!attribute [r] properties
#   @return [Hash] Map of propery names and associated values
class RestEmbeddedCartridge10 < OpenShift::Model
  attr_accessor :type, :name, :links, :properties, :status_messages

  def initialize(cart, app, cinst, url, status_messages, nolinks=false)
    self.name = cart.name
    self.type = "standalone"
    self.type = "embedded" unless cart.is_web_framework?
    self.status_messages = status_messages

    self.properties = {}
    if app
      self.properties = cinst.component_properties

      domain_id = app.domain_namespace
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
          } unless nolinks
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end