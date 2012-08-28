
class RestScalingInfo < StickShift::Model
  attr_accessor  :current_scale, :scales_with, :scales_from, :scales_to
  
  def initialize(group_instance, cartridge)
    if group_instance
      app = group_instance.app
      self.current_scale = group_instance.gears.length
      self.scales_with = nil
      app.embedded.each { |cart_name, cart_info|
        cart = CartridgeCache::find_cartridge(cart_name)
        if cart.categories.include? "scales"
          self.scales_with = cart.name
          break
        end
      }
      self.scales_from = group_instance.min
      self.scales_to = group_instance.max
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
    options[:tag_name] = "scaling_info"
    super(options)
  end
end
