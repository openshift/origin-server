##
# @api REST
# Describes an Cartridge
# @version 1.1
#
# Example:
#   ```
#   <cartridge>
#     <name>php-5.4</name>
#     <status-messages nil="true"/>
#     <version>5.4.10</version>
#     <display-name>PHP 5.4</display-name>
#     <description>PHP is a general-purpose server-side scripting language originally designed for Web development to produce dynamic Web pages. Popular development frameworks include: CakePHP, Zend, Symfony, and Code Igniter.</description>
#     <license>The PHP License, version 3.0</license>
#     <license-url>http://www.php.net/license/3_0.txt</license-url>
#     <tags>
#       <tag>service</tag>
#       <tag>php</tag>
#       <tag>web_framework</tag>
#     </tags>
#     <website>http://www.php.net</website>
#     <type>standalone</type>
#     <usage-rates/>
#     <scales-from>1</scales-from>
#     <scales-to>1</scales-to>
#     <current-scale>1</current-scale>
#     <gear-profile>small</gear-profile>
#     <base-gear-storage>1</base-gear-storage>
#     <additional-gear-storage>0</additional-gear-storage>
#     <collocated-with/>
#     <supported-scales-from>1</supported-scales-from>
#     <supported-scales-to>1</supported-scales-to>
#     <properties>
#       <property>
#         <name>OPENSHIFT_TMP_DIR</name>
#         <type>environment</type>
#         <description>Directory to store application temporary files.</description>
#       </property>
#       ...
#     </properties>
#     <scales-with nil="true"/>
#     <help-topics>
#       <Developer-Center>https://openshift.redhat.com/community/developers</Developer-Center>
#     </help-topics>
#     <links>
#       ...
#     </links>
#   </cartridge>
#   ```
#
# @!attribute [r] type
#   @deprecated
#   @return [String] "standalone" or "embedded".
# @!attribute [r] name
#   @return [String] Name of the cartridge
# @!attribute [r] version
#   @return [String] Version of the packaged software in the cartridge
# @!attribute [r] license
#   @return [String] License of the packaged software in the cartridge
# @!attribute [r] license_url
#   @return [String] URI to the license file for the packaged software in the cartridge
# @!attribute [r] tags
#   @return [Array<String>] Array of tags associated with the cartridge
# @!attribute [r] website
#   @return [String] URI to the website for the packaged software in the cartridge
# @!attribute [r] help_topics
#   @return [Hash] Map of topics and associated URIs that can provide help on how to use and configure this cartridge
# @!attribute [r] properties
#   @return [Array<Property>] List of environment variables and property values that are exposed by this cartridge and usable in application code.
# @!attribute [r] display_name
#   @return [String] Formatted name used by CLI and UIs
# @!attribute [r] description
#   @return [String] Description of the cartridge used by CLI and UIs
# @!attribute [r] scales_from
#   @return [Integer] User specified minimum scale for the cartridge
# @!attribute [r] scales_to
#   @return [Integer] User specified maximum scale for the cartridge
# @!attribute [r] supported_scales_from
#   @return [Integer] Cartridge supported minimum scale
# @!attribute [r] supported_scales_from
#   @return [Integer] Cartridge supported maximum scale
# @!attribute [r] current_scale
#   @return [Integer] Current number of gears used to run this cartridge
# @!attribute [r] scales_with
#   @return [Array<String>] Names of other cartridges that scale along with this cartridge and run on the same set of gears
# @!attribute [r] usage_rates
#   @return [Array<Object>]
class RestCartridge < OpenShift::Model
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website, 
    :help_topics, :properties, :display_name, :description, :scales_from, :scales_to,
    :supported_scales_to, :supported_scales_from, :current_scale, :scales_with, :usage_rates

  def initialize(cart)
    self.name = cart.name
    self.version = cart.version
    self.display_name = cart.display_name
    self.description = cart.description
    self.license = cart.license
    self.license_url = cart.license_url
    self.tags = cart.categories
    self.website = cart.website
    self.type = "standalone"
    self.type = "embedded" if cart.is_embeddable?
    scale = cart.components_in_profile(nil).first.scaling
    unless scale.nil?
      self.scales_from = self.supported_scales_from = scale.min
      self.scales_to = self.supported_scales_to = scale.max
    end
    self.current_scale = 0
    scaling_cart = CartridgeCache.find_cartridge_by_category("scales")[0]
    self.scales_with = scaling_cart.name unless scaling_cart.nil?
    self.help_topics = cart.help_topics
    self.usage_rates = cart.usage_rates
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
