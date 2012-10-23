class Link < OpenShift::Model
  attr_accessor :rel, :method, :href, :required_params, :optional_params
  
  def initialize(rel, method, href, required_params=nil, optional_params=nil)
    self.rel = rel
    self.method = method
    self.href = href.to_s
    self.required_params = required_params || Array.new
    self.optional_params = optional_params || Array.new
  end
end