class RestDomain < StickShift::Model
  attr_accessor :id, :suffix, :links
  include LegacyBrokerHelper
  
  def initialize(domain, url)
    self.id = domain.namespace
    self.suffix = Rails.application.config.ss[:domain_suffix] 

    carts = get_cached("cart_list_standalone", :expires_in => 21600.seconds) do
      Application.get_available_cartridges("standalone")
    end
    
    self.links = {
      "GET" => Link.new("Get domain", "GET", URI::join(url, "domains/#{id}")),
      "LIST_APPLICATIONS" => Link.new("List applications", "GET", URI::join(url, "domains/#{id}/applications")),
      "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domains/#{id}/applications"), 
        [Param.new("name", "string", "Name of the application")], 
        [OptionalParam.new("cartridge", "string", "framework-type, e.g: php-5.3", carts),
        OptionalParam.new("template", "string", "UUID of the application template"),
        OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
        OptionalParam.new("gear_profile", "string", "The size of the gear", ["small", "micro", "medium", "large", "exlarge", "jumbo"], "small")
      ]),
      "UPDATE" => Link.new("Update domain", "PUT", URI::join(url, "domains/#{id}"),[
        Param.new("id", "string", "Name of the domain")
      ]),
      "DELETE" => Link.new("Delete domain", "DELETE", URI::join(url, "domains/#{id}"),nil,[
        OptionalParam.new("force", "boolean", "Force delete domain.  i.e. delete any applications under this domain", [true, false], false)
      ])
    }
  end
  
  def to_xml(options={})
    options[:tag_name] = "domain"
    super(options)
  end
  
end
