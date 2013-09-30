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
class RestDomain12 < OpenShift::Model
  attr_accessor :id, :suffix, :creation_time, :links

  def initialize(domain, url, nolinks=false)
    self.id = domain.namespace
    self.suffix = Rails.application.config.openshift[:domain_suffix]

    if not domain.application_count.nil?
      @application_count = domain.application_count
      @gear_counts = domain.gear_counts || {}
    end

    unless nolinks
      valid_sizes = domain.allowed_gear_sizes
      blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
      carts = CartridgeCache.cartridge_names("web_framework")

      self.links = {
        "GET" => Link.new("Get domain", "GET", URI::join(url, "domain/#{id}")),
        "LIST_APPLICATIONS" => Link.new("List applications", "GET", URI::join(url, "domain/#{id}/applications")),
        "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domain/#{id}/applications"),
          [Param.new("name", "string", "Name of the application",nil,blacklisted_words)],
          [OptionalParam.new("cartridges", "array", "Array of one or more cartridge names. i.e. [\"php-5.3\", \"mongodb-2.2\"]", carts),
          OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
          OptionalParam.new("gear_profile", "string", "The size of the gear", valid_sizes, valid_sizes[0]),
          OptionalParam.new("initial_git_url", "string", "A URL to a Git source code repository that will be the basis for this application."),
          (OptionalParam.new("cartridges[][url]", "string", "A URL to a downloadable cartridge. You may specify an multiple urls via {'cartridges' : [{'url':'http://...'}, ...]}") if Rails.application.config.openshift[:download_cartridges_enabled]),
          OptionalParam.new("environment_variables", "array", "Add or Update application environment variables, e.g.:[{'name':'FOO', 'value':'123'}, {'name':'BAR', 'value':'abc'}]")
        ].compact),
        "UPDATE" => Link.new("Update domain", "PUT", URI::join(url, "domain/#{id}"),
          [Param.new("id", "string", "Name of the domain")],
          [OptionalParam.new("allowed_gear_sizes", "array", "Array of zero or more gear sizes allowed on this domain", OpenShift::ApplicationContainerProxy.valid_gear_sizes)],
        ),
        "DELETE" => Link.new("Delete domain", "DELETE", URI::join(url, "domain/#{id}"),nil,[
          OptionalParam.new("force", "boolean", "Force delete domain.  i.e. delete any applications under this domain", [true, false], false)
        ]),
        "LIST_MEMBERS" => Link.new("List members of this domain", "GET", URI::join(url, "domain/#{id}/members")),
        "LEAVE" => Link.new("Leave this domain", "DELETE", URI::join(url, "domain/#{id}/members/self")),
        "UPDATE_MEMBERS" => Link.new("Add or remove one or more members to this domain.", "POST", URI::join(url, "domain/#{id}/members"),
          [Param.new("role", "string", "The role the user should have on the domain", Role.all)],
          [OptionalParam.new("id", "string", "Unique identifier of the user"),
          OptionalParam.new("login", "string", "The user's login attribute")]
        ),
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "domain"
    super(options)
  end
end
