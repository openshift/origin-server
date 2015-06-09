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
  attr_accessor :id, :name, :suffix, :members, :allowed_gear_sizes, :creation_time, :links, :available_gears, :max_storage_per_gear, :usage_rates, :private_ssl_certificates

  def initialize(domain, url, nolinks=false)
    self.id = domain._id
    self.name = domain.namespace
    self.suffix = Rails.application.config.openshift[:domain_suffix]
    self.creation_time = domain.created_at
    self.members = domain.members.map{ |m| RestMember.new(m, domain.owner_id == m._id, url, domain, nolinks) }

    # Capabilities
    self.allowed_gear_sizes = (domain.allowed_gear_sizes & domain.owner.allowed_gear_sizes)
    self.available_gears = domain.available_gears
    self.max_storage_per_gear = domain.max_storage_per_gear
    self.usage_rates = domain.usage_rates
    self.private_ssl_certificates = domain.private_ssl_certificates

    unless domain.application_count.nil?
      @application_count = domain.application_count
      @gear_counts = domain.gear_counts || {}
    end

    unless nolinks
      blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted

      self.links = {
        "GET" => Link.new("Get domain", "GET", URI::join(url, "domain/#{name}")),
        "ADD_APPLICATION" => Link.new("Create new application", "POST", URI::join(url, "domain/#{name}/applications"),
          [Param.new("name", "string", "Name of the application", nil, blacklisted_words)],
          [OptionalParam.new("cartridges", "array", "Array of one or more cartridge names"),
          OptionalParam.new("scale", "boolean", "Mark application as scalable", [true, false], false),
          OptionalParam.new("gear_size", "string", "The size of the gear", allowed_gear_sizes, allowed_gear_sizes[0]),
          OptionalParam.new("initial_git_url", "string", "A URL to a Git source code repository that will be the basis for this application.", ['', OpenShift::Git::EMPTY_CLONE_SPEC]),
          OptionalParam.new("cartridges[][name]", "string", "Name of a cartridge."),
          OptionalParam.new("cartridges[][gear_size]", "string", "Gear size for the cartridge.", allowed_gear_sizes, allowed_gear_sizes[0]),
          (OptionalParam.new("cartridges[][url]", "string", "A URL to a downloadable cartridge. You may specify an multiple urls via {'cartridges' : [{'url':'http://...'}, ...]}") if Rails.application.config.openshift[:download_cartridges_enabled]),
          OptionalParam.new("environment_variables", "array", "Add or Update application environment variables, e.g.:[{'name':'FOO', 'value':'123'}, {'name':'BAR', 'value':'abc'}]"),
          OptionalParam.new("region", "string", "Restrict application to the given region")
        ].compact),
        "LIST_APPLICATIONS" => Link.new("List applications for a domain", "GET", URI::join(url, "domain/#{name}/applications")),
        "LIST_MEMBERS" => Link.new("List members of this domain", "GET", URI::join(url, "domain/#{name}/members")),
        "UPDATE_MEMBERS" => Link.new("Add or remove one or more members to this domain.", "PATCH", URI::join(url, "domain/#{name}/members"),
          [Param.new("role", "string", "The role the member should have on the domain", Role.all)],
          [OptionalParam.new("type", "string", "The member's type. i.e. user or team", ["user", "team"], "user"),
          OptionalParam.new("id", "string", "Unique identifier of the member for the given member type (user or team ID)"),
          OptionalParam.new("login", "string", "The user's login attribute"),
          OptionalParam.new("members", "Array", "An array of members to add with corresponding type and role. e.g. {'members': [{'login': 'foo', 'type': 'user', 'role': 'view'}, {'id': '5326534e2046fde9d3000001', 'type': 'team', 'role': 'none'}]}")]
        ),
        "LEAVE" => Link.new("Remove yourself as a member of the domain", "DELETE", URI::join(url, "domain/#{name}/members/self")),
        "UPDATE" => Link.new("Update domain", "PUT", URI::join(url, "domain/#{name}"),
          [Param.new("name", "string", "Name of the domain")],
          [OptionalParam.new("allowed_gear_sizes", "array", "Array of zero or more gear sizes allowed on this domain", OpenShift::ApplicationContainerProxy.valid_gear_sizes - OpenShift::ApplicationContainerProxy.hidden_gear_sizes)],
        ),
        "DELETE" => Link.new("Delete domain", "DELETE", URI::join(url, "domain/#{name}"),nil,[
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
