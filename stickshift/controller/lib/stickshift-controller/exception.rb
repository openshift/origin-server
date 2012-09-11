class StickShift::GearLimitReachedException < StickShift::SSException; end
class StickShift::ApplicationValidationException < StickShift::SSException
  attr_accessor :app
  
  def initialize(app)
    self.app = app
    super()
  end
end