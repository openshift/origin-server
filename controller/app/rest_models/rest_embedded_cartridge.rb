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
# @!attribute [r] base_gear_storage
#   @return [Integer] Number of GB of disk space assoicated with gear profile that this cartridge is running on
# @!attribute [r] additional_gear_storage
#   @return [Integer] Additional number of GB of disk space (beyond the base provided by the gear profile)
# @!attribute [r] gear_profile
#   @return [Integer] Gear profile fo the gears this cartridge is running on
# @!attribute [r] collocated_with
#   @return [Array<String>] Array of names of other cartridge that share the same gear(s) with this cartridge
# @!attribute [r] status_messages
#   @return [Array<String>] Status messages returned back from the cartridge
# @!attribute [r] usage_rates
#   @return [Array<Object>]
class RestEmbeddedCartridge < OpenShift::Model
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website, :url,
    :help_topics, :links, :properties, :display_name, :description, :scales_from,
    :scales_to, :current_scale, :supported_scales_from, :supported_scales_to,
    :scales_with, :base_gear_storage, :additional_gear_storage, :gear_profile, :collocated_with,
    :status_messages, :usage_rates

  def initialize(cart, comp, app, cinst, colocated_cinsts, scale, url, status_messages, nolinks=false)
    self.name = cart.name
    self.status_messages = status_messages
    self.version = cart.version
    self.display_name = cart.display_name
    self.description = cart.description
    self.license = cart.license
    self.license_url = cart.license_url
    self.tags = cart.categories
    self.website = cart.website
    self.url = nil
    if app.downloaded_cartridges.has_key? cart.name
      app.downloaded_cart_map.each { |cname,chash|
        if chash["versioned_name"]==cart.name or cname==cart.name
          self.url = chash["url"]
          break
        end
      }
    end
    self.type = "standalone"
    self.type = "embedded" if cart.is_embeddable?
    self.usage_rates = cart.usage_rates

    unless scale.nil?
      self.scales_from = scale[:min]
      self.scales_to = scale[:max]
      self.current_scale = scale[:current]
      # self.scales_from = self.scales_to = self.current_scale = 1 if cinst.is_singleton?
      if cinst.is_sparse?
        self.scales_from = cinst.get_component.scaling.min
        self.scales_to = cinst.get_component.scaling.max
        self.current_scale = cinst.group_instance.get_gears(cinst).length
      end
      self.gear_profile = scale[:gear_size]
      self.base_gear_storage = Gear.base_filesystem_gb(self.gear_profile)
      self.additional_gear_storage = scale[:additional_storage]

      self.collocated_with = colocated_cinsts.map{ |c| c.cartridge_name }
    end

    unless comp.nil?
      self.supported_scales_from = comp.scaling.min

      if app && !app.scalable && comp.scaling.max == -1
        self.supported_scales_to = 1
      else
        self.supported_scales_to = comp.scaling.max
      end
    end

    self.properties = []
    if app.nil?
      #self.provides = cart.features
    else
      #self.provides = app.get_feature(cinst.cartridge_name, cinst.component_name)
      prop_values = cinst.component_properties
      cart.cart_data_def.each do |data_def|
        property = {}
        property["name"] = data_def["Key"]
        property["type"] = data_def["Type"]
        property["description"] = data_def["Description"]
        # checking for prop_values.empty? handles the case when prop_values is an empty array
        property["value"] = prop_values[data_def["Key"]] unless prop_values.nil? or prop_values.empty? or prop_values[data_def["Key"]].nil?
        self.properties << property
      end

      self.scales_with = nil
      app.component_instances.each do |component_instance|
        cart = CartridgeCache::find_cartridge(component_instance.cartridge_name, app)
        if cart.categories.include?("scales")
          self.scales_with = component_instance.cartridge_name
          break
        end
      end
    end
    self.help_topics = cart.help_topics

    if app and !nolinks
      app_id = app._id
      if not app_id.nil?
        self.links = {
            "GET" => Link.new("Get cartridge", "GET", URI::join(url, "application/#{app_id}/cartridge/#{name}")),
            "UPDATE" => Link.new("Update cartridge configuration", "PUT", URI::join(url, "application/#{app_id}/cartridge/#{name}"), nil, [
              OptionalParam.new("additional_gear_storage", "integer", "Additional filesystem storage in gigabytes on each gear having cartridge #{name}"),
              OptionalParam.new("scales_from", "integer", "Minimum number of gears having cartridge #{name}"),
              OptionalParam.new("scales_to", "integer", "Maximum number of gears having cartridge #{name}")
            ]),
            "START" => Link.new("Start cartridge", "POST", URI::join(url, "application/#{app_id}/cartridge/#{name}/events"), [
              Param.new("event", "string", "event", "start")
            ]),
            "STOP" => Link.new("Stop cartridge", "POST", URI::join(url, "application/#{app_id}/cartridge/#{name}/events"), [
              Param.new("event", "string", "event", "stop")
            ]),
            "RESTART" => Link.new("Restart cartridge", "POST", URI::join(url, "application/#{app_id}/cartridge/#{name}/events"), [
              Param.new("event", "string", "event", "restart")
            ]),
            "RELOAD" => Link.new("Reload cartridge", "POST", URI::join(url, "application/#{app_id}/cartridge/#{name}/events"), [
              Param.new("event", "string", "event", "reload")
            ]),
            "DELETE" => Link.new("Delete cartridge", "DELETE", URI::join(url, "application/#{app_id}/cartridge/#{name}"))
          }
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
