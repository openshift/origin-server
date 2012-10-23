class Message < OpenShift::Model
  attr_accessor :severity, :text, :exit_code, :field
  
  def initialize(severity=:info, text=nil, exit_code=nil, field=nil)
    self.severity = severity
    self.text = text
    self.exit_code = exit_code
    self.field = field
  end
end