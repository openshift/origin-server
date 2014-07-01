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
#       <Developer-Center>https://www.openshift.com/developers</Developer-Center>
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
# @!attribute [r] scales_with
#   @return [Array<String>] Names of other cartridges that scale along with this cartridge and run on the same set of gears
# @!attribute [r] usage_rates
#   @return [Array<Object>]
# @!attribute [r] valid_gear_sizes
#   @return [Array<String>]
class RestCartridge < OpenShift::Model
  attr_accessor :id, :type, :name, :version, :license, :license_url, :tags, :website,
    :help_topics, :properties, :display_name, :description, :scales_from, :scales_to,
    :supported_scales_to, :supported_scales_from, :scales_with, :usage_rates,
    :creation_time, :automatic_updates

  def initialize(cart)
    self.name = cart.name
    self.id = cart.id
    self.version = cart.version
    self.display_name = cart.display_name
    self.description = cart.description
    self.license = cart.license
    self.license_url = cart.license_url
    self.tags = cart.categories
    self.website = cart.website
    self.type = "standalone"
    self.type = "embedded" unless cart.is_web_framework?
    scale = cart.components.first.scaling
    if not scale.nil?
      self.supported_scales_from = scale.min
      self.supported_scales_to = scale.max
    else
      self.supported_scales_from = 1
      self.supported_scales_to = -1
    end
    self.help_topics = cart.help_topics
    self.usage_rates = cart.usage_rates
    if requires = CartridgeCache.find_requires_for(cart).presence
      @requires = requires
    end

    @maintained_by = "redhat" if cart.cartridge_vendor == "redhat"
    self.automatic_updates = cart.manifest_url.blank? && !cart.categories.include?('no_updates')

    self.creation_time = cart.created_at
    if cart.activated_at
      @activation_time = cart.activated_at.in_time_zone
    end

    @obsolete = true if cart.is_obsolete?
    @url = cart.manifest_url if cart.manifest_url.present?
    @valid_gear_sizes = Rails.application.config.openshift[:cartridge_gear_sizes][cart.name] if Rails.application.config.openshift[:cartridge_gear_sizes][cart.name].any?

  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
