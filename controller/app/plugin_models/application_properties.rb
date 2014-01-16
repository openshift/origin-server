class ApplicationProperties
  attr_accessor :id, :name, :web_cartridge

  def initialize(app)
    self.id = app._id.to_s
    self.name = app.name
    app.requires(true).each do |feature|
      cart = CartridgeCache.find_cartridge_or_raise_exception(feature, app)
      if cart.is_web_framework?
        self.web_cartridge = cart.name
        break
      end
    end
  end
end
