##
# Entry point for the Broker REST API
# @api REST
class ApiController < BaseController
  skip_before_filter :check_outage, :authenticate_user!, :check_controller_scopes!, :only => :show

  ##
  # Returns an array of {http://en.wikipedia.org/wiki/HATEOAS HATEOAS} links describing the REST API. All REST replies
  # are wrappen in a [RestReply] object which provides information about the API version, request success or failure,
  # and returned object type.
  #
  # @note This method may or may not require authenticated access depending on the authentication plugin that is configured.
  # 
  # URL: /api
  #
  # Action: GET
  # 
  # @return [RestReply<Array<Link>>] Array of links for the rest of the REST API.
  def show
    blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
    links = {
      "API" => Link.new("API entry point", "GET", URI::join(get_url, "api")),
      "GET_ENVIRONMENT" => Link.new("Get environment information", "GET", URI::join(get_url, "environment")),
      "GET_USER" => Link.new("Get user information", "GET", URI::join(get_url, "user")),
      "ADD_DOMAIN" => Link.new("Create new domain", "POST", URI::join(get_url, "domains"), [
        Param.new(requested_api_version <= 1.5 ? "id" : "name", "string", "Name of the domain",nil,blacklisted_words)
      ], [
        (OptionalParam.new("allowed_gear_sizes", "array", "A list of gear sizes that are allowed to be created on this domain", OpenShift::ApplicationContainerProxy.valid_gear_sizes - OpenShift::ApplicationContainerProxy.hidden_gear_sizes) if requested_api_version >= 1.5),
      ].compact),
      "LIST_DOMAINS" => Link.new("List all domains you have access to", "GET", URI::join(get_url, "domains")),
      "LIST_DOMAINS_BY_OWNER" => Link.new("List domains by owner", "GET", URI::join(get_url, "domains"), [
        Param.new("owner", "string", "Return only the domains owned by the specified user id or identity.  Use @self to refer to the current user.", ['@self'], [])
        ]),
      "SHOW_DOMAIN" => Link.new("Retrieve a domain by its name", "GET", URI::join(get_url, "domain/:name"), [
        Param.new(":name", "string", "Unique name of the domain", nil, [])
      ]),
      "SHOW_APPLICATION_BY_DOMAIN"  => Link.new("Retrieve an application by its name and domain", "GET", URI::join(get_url, "domain/:domain_name/application/:name"), [
        Param.new(":domain_name", "string", "Unique name of the domain", nil, []),
        Param.new(":name", "string", "Name of the application", nil, []),
      ]),
      "LIST_CARTRIDGES" => Link.new("List public cartridges", "GET", URI::join(get_url, "cartridges"), [], [
        OptionalParam.new("category", "string", "Show all cartridges with the given category"),
      ]),
      "SHOW_CARTRIDGE"  => Link.new("Retrieve a public cartridge by name", "GET", URI::join(get_url, "cartridge/:name"), [
        Param.new(":name", "string", "Name of the cartridge", nil, [])
      ]),
      "SHOW_CARTRIDGE_BY_ID"  => Link.new("Retrieve a cartridge by id", "GET", URI::join(get_url, "cartridge/:id"), [
        Param.new(":id", "string", "Unique identifier of the cartridge", nil, [])
      ]),
      "ADD_TEAM" => Link.new("Create new team", "POST", URI::join(get_url, "teams"), [
        Param.new("name", "string", "Name of the team")]),
      "LIST_TEAMS" => Link.new("List all teams you are a member of", "GET", URI::join(get_url, "teams")),
      "LIST_TEAMS_BY_OWNER" => Link.new("List teams by owner", "GET", URI::join(get_url, "teams"), [
        Param.new("owner", "string", "Return only the teams owned by the specified user id or identity.  Use @self to refer to the current user.", ['@self'], [])
        ]),
      "SHOW_TEAM" => Link.new("Retrieve a team by it's id", "GET", URI::join(get_url, "team/:id"), [
        Param.new(":id", "string", "Id of the team")
      ]),
      "SEARCH_TEAMS" => Link.new("Search teams by name", "GET", URI::join(get_url, "teams"), [
        Param.new("search", "string", "Search string must be at least 2 characters"),
        Param.new("global", "boolean", "Search global teams", [true, false])
      ]),
      "LIST_REGIONS" => Link.new("List all regions", "GET", URI::join(get_url, "regions"))
    }

    links.merge!({
      "LIST_APPLICATIONS" => Link.new("List application", "GET", URI::join(get_url, "applications")),
      "LIST_APPLICATIONS_BY_OWNER" => Link.new("List applications by owner", "GET", URI::join(get_url, "applications"), [
        Param.new("owner", "string", "Return only the applications owned by the specified user id or identity.  Use @self to refer to the current user.", ['@self'], [])
      ]),
      "SHOW_APPLICATION" => Link.new("Retrieve application by id", "GET", URI::join(get_url, "application/:id"), [
        Param.new(":id", "string", "Unique identifier of the application", nil, [])
      ])
    }) if requested_api_version >= 1.5

    links.merge!({
      "LIST_AUTHORIZATIONS" => Link.new("List authorizations", "GET", URI::join(get_url, "user/authorizations")),
      "SHOW_AUTHORIZATION"  => Link.new("Retrieve authorization :id", "GET", URI::join(get_url, "user/authorization/:id"), [
        Param.new(":id", "string", "Unique identifier of the authorization", nil, [])
      ]),
      "ADD_AUTHORIZATION" => Link.new("Add new authorization", "POST", URI::join(get_url, "user/authorizations"), [], [
        OptionalParam.new("scope", "string", scope_message, Scope.describe_all.map{ |arr| arr.first }, Scope.default || nil),
        OptionalParam.new("note", "string", "A description to remind you what this authorization is for."),
        OptionalParam.new("expires_in", "integer", "The number of seconds before this authorization expires. Out of range values will be set to the maximum allowed time.", nil, -1),
        OptionalParam.new("reuse", "boolean", "Attempt to locate and reuse an authorization that matches the scope and note and has not yet expired.", [true, false], false),
      ]),
    }) if requested_api_version >= 1.2

    base_url = Rails.application.config.openshift[:community_quickstarts_url]
    if base_url.nil?
      quickstart_links = {
        "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(get_url, "quickstarts")),
        "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(get_url, "quickstart/:id"), [
          Param.new(":id", "string", "Unique identifier of the quickstart", nil, [])
        ]),
      }
      links.merge! quickstart_links
    else
      base_url = URI.join(get_url, base_url.gsub(/\{host\}/, request.host)).to_s
      quickstart_links = {
        "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(base_url, "v1/quickstarts/promoted.json")),
        "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(base_url, "v1/quickstarts/:id"), [
          Param.new(":id", "string", "Unique identifier of the quickstart", nil, [])
        ]),
        "SEARCH_QUICKSTARTS" => Link.new("Search quickstarts", "GET", URI::join(base_url, "v1/quickstarts.json"), [
          Param.new("search", "string", "The search term to use for the quickstart", nil, [])
        ]),
      }
      links.merge! quickstart_links
    end

    @reply = new_rest_reply(:ok, "links", links)
    respond_with @reply, :status => @reply.status
  end

  protected
    include ActionView::Helpers::DateHelper
    def scope_message
      "Select one or more scopes that this authorization will grant access to:\n\n#{Scope.describe_all.map{ |n, m, defe, maxe| "*  #{n}\n   #{m}#{scope_expires_message(defe,maxe)}"}.join("\n")}"
    end
    def scope_expires_message(default_exp, maximum_exp)
      " Valid for #{distance_of_time_in_words(default_exp, 0)}."
    end
end
