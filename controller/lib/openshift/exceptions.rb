module OpenShift
  class GearLimitReachedException < UserException; end

  class ScaleConflictException < UserException
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

  class UnfulfilledRequirementException < OOException
    attr_reader :feature, :cart_name

    def initialize(feature, cart_name)
      @feature = feature
      @cart_name = cart_name
      super
    end

    def to_s
      feature.is_a?(Array) ? "None of the cartridge requirements #{feature.join(", ")} for #{cart_name} were available to install." : "The cartridge requirement #{feature} for #{cart_name} is not available to install."
    end
  end

  class ValidationException < OOException
    attr_reader :resource

    def initialize(resource)
      @resource = resource
      super
    end
  end

  class ApplicationValidationException < ValidationException
    attr_reader :app

    def initialize(app)
      @app = app
      super
    end
  end

  class OperationForbidden < AccessDeniedException
  end

  class ApplicationOperationFailed < OOException; end
end