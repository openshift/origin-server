class RestDomain13 < OpenShift::Model
  attr_accessor :id, :suffix, :links
  
  def initialize(domain, url, nolinks=false)
    self.id = domain.namespace
    self.suffix = Rails.application.config.openshift[:domain_suffix] 
    
    unless nolinks      
      valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes(domain.owner)
      blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
      carts = CartridgeCache.cartridge_names("web_framework")

      self.links = {
        "GET" => Link.new("Get domain", "GET", URI::join(url, "domains/#{id}")),
        "LIST_APPLICATIONS" => Link.new("List applications", "GET", URI::join(url, "domains/#{id}/applications")),
        "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domains/#{id}/applications"), 
          [Param.new("name", "string", "Name of the application",nil,blacklisted_words)], 
          [OptionalParam.new("cartridges", "array", "Array of one or more cartridge names. i.e. [\"php-5.3\", \"mongodb-2.2\"]", carts),
          OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
          OptionalParam.new("gear_profile", "string", "The size of the gear", valid_sizes, valid_sizes[0]),
          OptionalParam.new("init_git_url", "string", "Initial git URL"),
        ]),
        "UPDATE" => Link.new("Update domain", "PUT", URI::join(url, "domains/#{id}"),[
          Param.new("id", "string", "Name of the domain")
        ]),
        "DELETE" => Link.new("Delete domain", "DELETE", URI::join(url, "domains/#{id}"),nil,[
          OptionalParam.new("force", "boolean", "Force delete domain.  i.e. delete any applications under this domain", [true, false], false)
        ])
      }
    end
  end
  
  def to_xml(options={})
    options[:tag_name] = "domain"
    super(options)
  end
end