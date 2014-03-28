class ApplicationProperties
  attr_accessor :id, :name, :web_cartridge

  def initialize(app)
    self.id = app._id.to_s
    self.name = app.name
    if cart = app.web_cartridge
      self.web_cartridge = cart.name
    end
  end
end
