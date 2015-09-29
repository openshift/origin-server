module OpenShift
  class OOException < StandardError
    attr_accessor :code, :resultIO

    # Uncommon server errors
    SYSTEM_ERROR_CONTEXT = {
      1   => "Non-specific error",
      140 => "No nodes available. If the problem persists contact support.",
      141 => "Cartridge exception.",
      142 => "Application is registered to an invalid node. If the problem persists contact support.",
      143 => "Node execution failure. If the problem persists contact support.",
      144 => "Error communicating with user validation system. If the problem persists contact support.",
      145 => "Error communicating with DNS system. If the problem persists contact support.",
      146 => "Gear creation exception."
    }
    # User errors
    USER_ERROR_CONTEXT = {
      1   => "Non-specific error",
      97  => "Invalid user credentials",
      99  => "User does not exist",
      100 => "An application with specified name already exists",
      101 => "An application with specified name does not exist and cannot be operated on",
      102 => "A user with login already exists",
      103 => "Given namespace is already in use",
      104 => "User's gear limit has been reached",
      105 => "Invalid application name",
      106 => "Invalid namespace",
      107 => "Invalid user login",
      108 => "Invalid SSH key",
      109 => "Invalid cartridge types",
      110 => "Invalid application type specified",
      111 => "Invalid action",
      112 => "Invalid API",
      113 => "Invalid auth key",
      114 => "Invalid auth iv",
      115 => "Too many cartridges of one type per user",
      116 => "Invalid SSH key type",
      117 => "Invalid SSH key name or tag",
      118 => "SSH key name does not exist",
      119 => "SSH key or key name not specified",
      120 => "SSH key name already exists",
      121 => "SSH key already exists",
      122 => "Last SSH key for user",
      123 => "No SSH key for user",
      124 => "Could not delete default or primary key",
      125 => "Invalid template",
      126 => "Invalid event",
      127 => "A domain with specified namespace does not exist and cannot be operated on",
      128 => "Could not delete domain because domain has valid applications",
      129 => "The application is not configured with this cartridge",
      130 => "Invalid parameters to estimates controller",
      131 => "Error during estimation",
      132 => "Insufficient Access Rights",
      133 => "Could not delete user",
      134 => "Invalid gear profile",
      135 => "Cartridge not found in the application",
      136 => "Cartridge already embedded in the application",
      137 => "Cartridge cannot be added or removed from the application",
      138 => "User deletion not permitted for normal or non-subaccount user",
      139 => "Could not delete user because user has valid domain or applications",
      140 => "Alias already in use",
      141 => "Unable to find nameservers for domain",
      150 => "A plan with specified id does not exist",
      151 => "Billing account was not found for user",
      152 => "Billing account status not active",
      153 => "User has more consumed gears than the new plan allows",
      154 => "User has gears that the new plan does not allow",
      155 => "Error getting account information from billing provider",
      156 => "Updating user plan on billing provider failed",
      157 => "Plan change not allowed for subaccount user",
      158 => "Domain already exists for user",
      159 => "User has additional filesystem storage that the new plan does not allow",
      160 => "User max gear limit capability does not match with current plan",
      161 => "User gear sizes capability does not match with current plan",
      162 => "User max untracked additional filesystem storage per gear capability does not match with current plan",
      163 => "Gear group does not exist",
      164 => "User is not allowed to change storage quota",
      165 => "Invalid storage quota value provided",
      166 => "Storage value not within allowed range",
      167 => "Invalid value for nolinks parameter",
      168 => "Invalid scaling factor provided. Value out of range.",
      169 => "Could not completely distribute scales_from to all groups",
      170 => "Could not resolve DNS",
      171 => "Could not obtain lock",
      172 => "Invalid or missing private key is required for SSL certificate",
      173 => "Alias does exist for this application",
      174 => "Invalid SSL certificate",
      175 => "User is not authorized to add private certificates",
      176 => "User has private certificates that the new plan does not allow",
      180 => "This command is not available in this application",
      181 => "User maximum tracked additional filesystem storage per gear capability does not match with current plan",
      182 => "User does not have gear_sizes capability provided by current plan",
      183 => "User does not have max_untracked_addtl_storage_per_gear capability provided by current plan",
      184 => "User does not have max_tracked_addtl_storage_per_gear capability provided by current plan",
      185 => "Cartridge X can not be added without cartridge Y",
      186 => "Invalid environment variables: expected array of hashes.",
      187 => "Invalid environment variable X. Valid keys name (required), value",
      188 => "Invalid environment variable name X: specified multiple times",
      189 => "Environment name X not found in application",
      190 => "Value not specified for environment variable X",
      191 => "Specify parameters name/value or environment_variables",
      192 => "Environment name X already exists in application",
      193 => "Environment variable deletion not allowed for this operation",
      194 => "Name can only contain letters, digits and underscore and cannot begin with a digit",
      210 => "Cannot override existing location for Git repository",
      211 => "Parent directory for Git repository does not exist",
      212 => "Could not find libra_id_rsa",
      213 => "Could not read from SSH configuration file",
      214 => "Could not write to SSH configuration file",
      215 => "Host could not be created or found",
      216 => "Error in Git pull",
      217 => "Destroy aborted",
      218 => "Not found response from request",
      219 => "Unable to communicate with server",
      220 => "Plan change is not allowed for this account",
      221 => "Plan change is not allowed at this time for this account. Wait a few minutes and try again. If problem persists contact support.",
      253 => "Could not open configuration file",
      255 => "Usage error"
    }

    def initialize(msg=nil, code=1, resultIO=nil)
      super(msg)
      @code = code
      @resultIO = resultIO
    end

    def self.system_error_context(code=nil)
      return 'No error code set' if code.nil?
      SYSTEM_ERROR_CONTEXT[code] || 'Unknown error'
    end

    def self.user_error_context(code=nil)
      return 'No error code set' if code.nil?
      USER_ERROR_CONTEXT[code] || 'Unknown error'
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
