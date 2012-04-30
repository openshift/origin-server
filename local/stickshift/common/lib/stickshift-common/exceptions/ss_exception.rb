module StickShift
  class SSException < StandardError
    attr_accessor :code, :resultIO

    def initialize(msg=nil, code=nil, resultIO=nil)
      super(msg)
      @code = code
      @resultIO = resultIO
    end
  end

  class NodeException < StickShift::SSException; end
  class InvalidNodeException < NodeException
    attr_accessor :server_identity

    def initialize(msg=nil, code=nil, resultIO=nil, server_identity=nil)
      super(msg, code, resultIO)
      @server_identity = server_identity
    end
  end
  class UserException < StickShift::SSException; end
  class UserKeyException < StickShift::SSException; end
  class AuthServiceException < StickShift::SSException; end
  class UserValidationException < StickShift::SSException; end
  class AccessDeniedException < UserValidationException; end
  class DNSException < StickShift::SSException; end
  class DNSNotFoundException < DNSException; end
end
