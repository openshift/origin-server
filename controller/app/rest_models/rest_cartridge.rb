class RestCartridge < OpenShift::Model
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website, 
    :help_topics, :properties, :display_name, :description, :scales_from, :scales_to,
    :supported_scales_to, :supported_scales_from, :current_scale, :scales_with

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
    self.type = "embedded" if cart.categories.include? "embedded"
    scale = cart.components_in_profile(nil).first.scaling
    unless scale.nil?
      self.scales_from = self.supported_scales_from = scale.min
      self.scales_to = self.supported_scales_to = scale.max
    end
    self.current_scale = 0
    scaling_cart = CartridgeCache.find_cartridge_by_category("scales")[0]
    self.scales_with = scaling_cart.name
    self.help_topics = cart.help_topics
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end
