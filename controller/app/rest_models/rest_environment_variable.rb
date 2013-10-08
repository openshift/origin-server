class RestEnvironmentVariable < OpenShift::Model
  attr_accessor :name, :value, :links
  
  def initialize(app, env_var, url, nolinks=false)
    self.name = env_var['name']
    self.value = env_var['value']
    app_id = app.uuid
    unless nolinks      
      self.links = {
        "GET" => Link.new("Get environment variable", "GET", URI::join(url, "application/#{app_id}/environment-variable/#{self.name}")),
        "UPDATE" => Link.new("Update environment variable", "PUT", URI::join(url, "application/#{app_id}/environment-variable/#{self.name}"),
          [Param.new("value", "string", "Value of the environment variable")]), 
        "DELETE" => Link.new("Delete environment variable", "DELETE", URI::join(url, "application/#{app_id}/environment-variable/#{self.name}"))
      }
    end
  end
  
  def to_xml(options={})
    options[:tag_name] = "environment-variable"
    super(options)
  end
end
