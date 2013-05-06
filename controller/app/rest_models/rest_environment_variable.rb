class RestEnvironmentVariable < OpenShift::Model
  attr_accessor :id, :links

  def initialize(name, app, url, nolinks=false)
    self.id = name
    
    if app and !nolinks
      domain_id = app.domain.namespace
      app_id = app.name
      if not app_id.nil? and not domain_id.nil?
        self.links = {
            "DELETE" => Link.new("Delete environment variable", "DELETE", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/environment_variables/#{id}"))
          }
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "environment_variable"
    super(options)
  end
end
