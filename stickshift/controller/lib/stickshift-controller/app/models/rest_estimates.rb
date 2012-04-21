class RestEstimates < StickShift::Model
  attr_accessor :links 
 
  def initialize(url)
    self.links = {
      "GET_ESTIMATE" => Link.new("Get application estimate", "GET", URI::join(url, "estimates/application"), [
        Param.new("descriptor", "string", "application requirements")
      ]) 
    }
  end
  
  def to_xml(options={})
    options[:tag_name] = "estimates"
    super(options)
  end
end
