##
# @api REST
# Describes an Domain (namespace)
# @version 1.1
# @see RestApplication
# @see RestDomain10
#
# Example:
#   ```
#   <domain>
#     <id>localns</id>
#     <suffix>example.com</suffix>
#     <links>
#        ...
#     </links>
#   </domain>
#   ```
#
# @!attribute [r] id
#   @return [String] namespace for this domain
# @!attribute [r] suffix
#   @return [String] DNS suffix under which the application is created. Eg: rhcloud.com
class RestDomain < OpenShift::Model
  attr_accessor :name, :suffix, :creation_time, :links
  
  def initialize(domain, owner, url, nolinks=false)
    self.name = domain.namespace
    self.suffix = Rails.application.config.openshift[:domain_suffix]
    self.creation_time = domain.created_at
    
    unless nolinks      
      valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes(owner)
      blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
      carts = CartridgeCache.cartridge_names("web_framework")

      self.links = {
        "GET" => Link.new("Get domain", "GET", URI::join(url, "domains/#{name}")),
        "LIST_APPLICATIONS" => Link.new("List applications", "GET", URI::join(url, "domains/#{name}/applications")),
        "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domains/#{name}/applications"), 
          [Param.new("name", "string", "Name of the application",nil,blacklisted_words)], 
          [OptionalParam.new("cartridges", "array", "Array of one or more cartridge names", carts),
          OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
          OptionalParam.new("gear_profile", "string", "The size of the gear", valid_sizes, valid_sizes[0]),
          OptionalParam.new("initial_git_url", "string", "A URL to a Git source code repository that will be the basis for this application.", ['*', OpenShift::Git::EMPTY_CLONE_SPEC]),
          (OptionalParam.new("cartridges[][url]", "string", "A URL to a downloadable cartridge. You may specify an multiple urls via {'cartridges' : [{'url':'http://...'}, ...]}") if Rails.application.config.openshift[:download_cartridges_enabled]),
          OptionalParam.new("environment_variables", "hash", "Add environment variables to the application, e.g.: {'FOO':'123', 'BAR':'abc'}")
        ].compact),
        "UPDATE" => Link.new("Update domain", "PUT", URI::join(url, "domains/#{name}"),[
          Param.new("name", "string", "Name of the domain")
        ]),
        "DELETE" => Link.new("Delete domain", "DELETE", URI::join(url, "domains/#{name}"),nil,[
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
