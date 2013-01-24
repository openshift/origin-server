# Messages to return to the REST client
# @!attribute [r] severity
#   @return [String] Severity of the message (debug, info, error)
# @!attribute [r] text
#   @return [String] Text of the message
# @!attribute [r] exit_code
#   @return [String] (Optional) Exit code
# @!attribute [r] field
#   @return [String] (Optional) field that this message applies to. Usually for validation failures.
class Message < OpenShift::Model
  attr_accessor :severity, :text, :exit_code, :field
  
  def initialize(severity=:info, text=nil, exit_code=nil, field=nil)
    self.severity = severity
    self.text = text
    self.exit_code = exit_code
    self.field = field
  end
end