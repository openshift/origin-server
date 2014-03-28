module OpenShift
  class OOException < StandardError
    attr_accessor :code, :resultIO

    def initialize(msg=nil, code=1, resultIO=nil)
      super(msg)
      @code = code
      @resultIO = resultIO
    end
  end

  class NodeException < OpenShift::OOException; end
  class NodeUnavailableException < NodeException; end
  class InvalidNodeException < NodeException
    attr_accessor :server_identity

    def initialize(msg=nil, code=nil, resultIO=nil, server_identity=nil)
      super(msg, code, resultIO)
      @server_identity = server_identity
    end
  end
  class GearsException < Exception
    attr_accessor :successful, :failed, :exception

    def initialize(successful=nil, failed=nil, exception=nil)
      @successful = successful
      @failed = failed
      @exception = exception
    end
  end

  class UserException < OpenShift::OOException
    attr_accessor :field, :response_code, :data
    def initialize(msg, code=nil, field=nil, resultIO=nil, response_code=nil, data=nil)
      super(msg, code, resultIO)
      @field = field
      @response_code = response_code
      @data = data
    end
  end
  #Not used removing class UserKeyException < OpenShift::OOException; end
  class AuthServiceException < OpenShift::OOException; end
  class UserValidationException < OpenShift::OOException; end
  class AccessDeniedException < UserValidationException; end
  class DNSException < OpenShift::OOException; end
  class DNSAlreadyExistsException < DNSException; end
  class DNSNotFoundException < DNSException; end
  class DNSLoginException < DNSException; end
  # not used removing class EstimatesException < OpenShift::OOException; end
  class LockUnavailableException < OpenShift::OOException; end
end
