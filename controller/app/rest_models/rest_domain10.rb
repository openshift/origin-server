##
# @api REST
# Describes an Domain (namespace)
# @version 1.0
# @see RestApplication10
# @see RestDomain
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
class RestDomain10 < OpenShift::Model
  attr_accessor :id, :suffix, :links

  def initialize(domain, url, nolinks=false)
    self.id = domain.namespace
    self.suffix = Rails.application.config.openshift[:domain_suffix] 

    unless nolinks
      valid_sizes = domain.allowed_gear_sizes
      blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted

      self.links = {
        "GET" => Link.new("Get domain", "GET", URI::join(url, "domains/#{id}")),
        "LIST_APPLICATIONS" => Link.new("List applications", "GET", URI::join(url, "domains/#{id}/applications")),
        "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domains/#{id}/applications"), 
          [Param.new("name", "string", "Name of the application",nil,blacklisted_words)], 
          [OptionalParam.new("cartridge", "string", "framework-type", CartridgeCache.web_framework_names),
          OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
          OptionalParam.new("initial_git_url", "string", "A URL to a Git source code repository that will be the basis for this application.", ['*', OpenShift::Git::EMPTY_CLONE_SPEC]),
          OptionalParam.new("gear_profile", "string", "The size of the gear", valid_sizes, valid_sizes[0])
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
