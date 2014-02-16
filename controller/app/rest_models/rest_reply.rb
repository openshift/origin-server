##
# @api REST
# Wrapper object for all REST API replies
# Example:
#   ```
#   <response>
#     <status>ok</status>
#     <type>cartridges</type>
#     <data>
#       <cartridge>
#       ...
#       </cartridge>
#     </data>
#     <messages/>
#     <version>1.0</version>
#     <supported-api-versions>
#       ...
#       <supported-api-version>1.2</supported-api-version>
#       <supported-api-version>1.3</supported-api-version>
#     </supported-api-versions>
#   </response>
#
# @attr [String] version The reply REST API version
# @attr [String] status The HTTP reply status.
#   @see {http://foo.com HTTP status codes}
# @attr [String] type Object type embedded in this REST reply
# @attr [Object] data The data being returned by this REST reply
# @attr [Array<Message>] messages Messages and errors returned in the REST reply
# @attr [Array<String>] supported_api_versions Other supported REST API versions
class RestReply < OpenShift::Model
  attr_accessor :version, :status, :type, :data, :messages, :supported_api_versions, :api_version

  def initialize(requested_api_version, status=nil, type=nil, data=nil)
    self.status = status
    self.type = type
    self.data = data
    self.messages = []
    self.version = requested_api_version.to_s 
    self.api_version = requested_api_version
    self.supported_api_versions = OpenShift::Controller::ApiBehavior::SUPPORTED_API_VERSIONS
  end

  def process_result_io(result_io)
    unless result_io.nil?
      if result_io.is_a? Array
        result_io.each do |r|
          process_result_io(r)
        end
      end
      if result_io.is_a? ResultIO
        messages.push(Message.new(:debug, result_io.debugIO.string)) unless result_io.debugIO.string.empty?
        messages.push(Message.new(:warning, result_io.messageIO.string)) unless result_io.messageIO.string.empty?
        messages.push(Message.new(:error, result_io.errorIO.string)) unless result_io.errorIO.string.empty?
        messages.push(Message.new(:result, result_io.resultIO.string)) unless result_io.resultIO.string.empty?
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "response"
    unless self.data.kind_of? Enumerable
      new_data = self.data
      self.data = [new_data]
    end
    super(options)
  end
end
