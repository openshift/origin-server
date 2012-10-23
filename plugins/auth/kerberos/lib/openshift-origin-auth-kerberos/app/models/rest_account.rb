class RestAccount < OpenShift::Model
  attr_accessor :username, :created_on

  def initialize(username, created_on)
    self.username, self.created_on = username, created_on
  end

  def to_xml(options={})
    options[:tag_name] = "account"
    super(options)
  end
end
