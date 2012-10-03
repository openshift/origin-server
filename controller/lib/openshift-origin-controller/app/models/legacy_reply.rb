class LegacyReply < OpenShift::Model
  attr_accessor :api, :api_c, :broker_c, :debug, :messages, :result, :data, :exit_code  
  
  API_VERSION    = "1.1.3"
  API_CAPABILITY = %w(placeholder)
  C_CAPABILITY   = %w(namespace rhlogin ssh app_uuid debug alter cartridge cart_type action app_name api)

  def initialize
    @api = API_VERSION
    @api_c = API_CAPABILITY
    @broker_c = C_CAPABILITY
    @debug = ""
    @messages = nil
  end
end