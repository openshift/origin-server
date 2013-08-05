##
# @api REST
# Describes an set of gears which run the same cartridges and share scaling limits.
# All cartridges in the gear group scale together.
#
# Example:
#   ```
#   <gear-group>
#     <uuid>51266cda6892df395200002b</uuid>
#     <name>51266cda6892df395200002b</name>
#     <gear-profile>small</gear-profile>
#     <gears>
#       <gear>
#         <id>51266cda6892df3952000001</id>
#         <state></state>
#       </gear>
#     </gears>
#     <cartridges>
#       <cartridge>
#         <name>php-5.4</name>
#         <display-name>PHP 5.4</display-name>
#         <tags>
#           <tag>service</tag>
#           <tag>php</tag>
#           <tag>web_framework</tag>
#         </tags>
#       </cartridge>
#       <cartridge>
#         <name>haproxy-1.4</name>
#         <display-name>OpenShift Web Balancer</display-name>
#         <tags>
#           <tag>web_proxy</tag>
#           <tag>scales</tag>
#           <tag>embedded</tag>
#         </tags>
#       </cartridge>
#     </cartridges>
#     <scales-from>1</scales-from>
#     <scales-to>-1</scales-to>
#     <base-gear-storage>1</base-gear-storage>
#     <additional-gear-storage>0</additional-gear-storage>
#     <ssh-url>ssh://5124897d6892dfe819000005@testapp-localns.example.com</ssh-url>
#   </gear-group>
#   ```
#
# @!attribute [r] uuid
#   @return [String] UUID that identified the gear group
# @!attribute [r] name
#   @return [String] UUID that identified the gear group
# @!attribute [r] gear_profile
#   @return [String] The profile of all gears in the gear group
# @!attribute [r] cartridges
#   @return [Array<Hash>] List of cartridges running on the gears within this gear group.
# @!attribute [r] gears
#   @return [Array<Hash>] List of gears running within this gear group.
# @!attribute [r] scales_from
#   @return [Integer] Minimum number of gears within this gear group
# @!attribute [r] scales_to
#   @return [Integer] Maximum number of gears within this gear group
# @!attribute [r] base_gear_storage
# @!attribute [r] base_gear_storage
#   @return [Integer] Number of GB of disk space assoicated with gear profile
# @!attribute [r] additional_gear_storage
#   @return [Integer] Additional number of GB of disk space (beyond the base provided by the gear profile)
# @!attribute [r] ssh_url
#   @return [String] username and FQDN that can be used to ssh into the this gear
class RestGearGroup < OpenShift::Model
  attr_accessor :id, :name, :gear_profile, :cartridges, :gears, :scales_from, :scales_to, :base_gear_storage, :additional_gear_storage

  def initialize(group_instance, gear_states = {}, app, url, nolinks, include_endpoints)
    self.id         = group_instance._id.to_s
    self.name         = self.id
    self.gear_profile = group_instance.gear_size
    self.gears        = group_instance.gears.map{ |gear|
      ghash = { :id => gear.uuid,
        :state => gear_states[gear.uuid] || 'unknown',
        :ssh_url => "ssh://#{app.ssh_uri(gear.app_dns ? nil: gear.uuid)}",
      }
      if include_endpoints
        ghash[:endpoints] = gear.port_interfaces.map { |pi| pi.to_hash }
      end
      ghash
    }

    self.cartridges   = group_instance.all_component_instances.map { |component_instance| 
      cart = CartridgeCache.find_cartridge_or_raise_exception(component_instance.cartridge_name, app)

      # Handling the case when component_properties is an empty array
      # This can happen if the mongo document is copied and pasted back and saved using a UI tool
      if component_instance.component_properties.nil? or component_instance.component_properties.is_a? Array
        component_instance.component_properties = {}
      end

      component_instance.component_properties.merge({
        :name => cart.name,
        :display_name => cart.display_name,
        :tags => cart.categories
      })
    }

    self.scales_from    = group_instance.min
    self.scales_to    = group_instance.max
    self.base_gear_storage = Gear.base_filesystem_gb(self.gear_profile)
    self.additional_gear_storage = group_instance.addtl_fs_gb
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
