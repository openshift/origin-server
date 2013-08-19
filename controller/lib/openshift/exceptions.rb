class OpenShift::GearLimitReachedException < OpenShift::UserException; end

class OpenShift::ScaleConflictException < OpenShift::UserException
  attr_accessor :cart, :comp, :requested_min, :requested_max, :comp_min, :comp_max

  def initialize(msg, cart, comp, requested_min, requested_max, comp_min, comp_max)
    super(msg)
    self.cart = cart
    self.comp = comp
    self.requested_min = requested_min
    self.requested_max = requested_max
    self.comp_min = comp_min
    self.comp_max = comp_max   
    super()
  end
end

class OpenShift::UnfulfilledRequirementException < OpenShift::OOException
  attr_accessor :feature

  def initialize(feature)
    self.feature = feature
    super
  end
end

class OpenShift::ApplicationValidationException < OpenShift::OOException
  attr_accessor :app

  def initialize(app)
    self.app = app
    super()
  end
end

class OpenShift::OperationForbidden < OpenShift::AccessDeniedException
end