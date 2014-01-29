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
class RestCartridge10 < OpenShift::Model
  attr_accessor :type, :name, :properties, :status_messages

  def initialize(cart)
    self.name = cart.name
    self.type = "standalone"
    self.type = "embedded" unless cart.is_web_framework?
    self.status_messages = nil
    self.properties = {}
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end