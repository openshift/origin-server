module OpenShift
  class OOException < StandardError
    attr_accessor :code, :resultIO

    def initialize(msg=nil, code=nil, resultIO=nil)
      super(msg)
      @code = code
      @resultIO = resultIO
    end
  end

  class NodeException < OpenShift::OOException; end
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

  class UserException < OpenShift::OOException; end
  class UserKeyException < OpenShift::OOException; end
  class AuthServiceException < OpenShift::OOException; end
  class UserValidationException < OpenShift::OOException; end
  class AccessDeniedException < UserValidationException; end
  class DNSException < OpenShift::OOException; end
  class DNSAlreadyExistsException < DNSException; end
  class DNSNotFoundException < DNSException; end
  class EstimatesException < OpenShift::OOException; end
  class LockUnavailableException < OpenShift::OOException; end
end
