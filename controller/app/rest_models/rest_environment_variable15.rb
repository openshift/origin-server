class RestEnvironmentVariable15 < OpenShift::Model
  attr_accessor :name, :value, :links
  
  def initialize(app, env_var, url, nolinks=false)
    self.name = env_var['name']
    self.value = env_var['value']
    domain_id = app.domain_namespace
    app_id = app.name
    unless nolinks      
      self.links = {
        "GET" => Link.new("Get environment variable", "GET", URI::join(url, "domain/#{domain_id}/application/#{app_id}/environment-variable/#{self.name}")),
        "UPDATE" => Link.new("Update environment variable", "PUT", URI::join(url, "domain/#{domain_id}/application/#{app_id}/environment-variable/#{self.name}"),
          [Param.new("value", "string", "Value of the environment variable")]), 
        "DELETE" => Link.new("Delete environment variable", "DELETE", URI::join(url, "domain/#{domain_id}/application/#{app_id}/environment-variable/#{self.name}"))
      }
    end
  end
  
  def to_xml(options={})
    options[:tag_name] = "environment-variable"
    super(options)
  end
end
