##
# @api REST
# Describes an Application
# @version 1.0
# @see RestApplication
#
# Example:
#   ```
#   <application>
#     <embedded>
#     </embedded>
#     <framework>php-5.4</framework>
#     <name>testapp</name>
#     <creation-time>2013-02-20T08:29:49Z</creation-time>
#     <uuid>5124897d6892dfe819000005</uuid>
#     <aliases/>
#     <gear-count>1</gear-count>
#     <domain-id>localns</domain-id>
#     <gear-profile>small</gear-profile>
#     <scalable>false</scalable>
#     <scale-min>1</scale-min>
#     <scale-max>1</scale-max>
#     <git-url>ssh://5124897d6892dfe819000005@testapp-localns.example.com/~/git/testapp.git/</git-url>
#     <app-url>http://testapp-localns.example.com/</app-url>
#     <ssh-url>ssh://5124897d6892dfe819000005@testapp-localns.example.com</ssh-url>
#     <health-check-path>health</health-check-path>
#     <building-with nil="true"/>
#     <building-app nil="true"/>
#     <build-job-url nil="true"/>
#     <links>
#       ...
#     </links>
#   </applications>
#   ```
#
# @!attribute [r] name
#   @return [String] Application name
# @!attribute [r] framework
#   @return [String] Web framework that runs on this application
# @!attribute [r] creation_time
#   @return [DateTime] Date and time the application was created
# @!attribute [r] uuid
#   @return [String] UUID for this application
# @!attribute [r] embedded
#   @return [Array<RestEmbeddedCartridge10>] Array of support cartridges running in this application
# @!attribute [r] aliases
#   @return [Array<String>] Array of DNS aliases associated with this application
# @!attribute [r] gear_count
#   @return [Integer] Number of gears used by this application
# @!attribute [r] domain_id
#   @return [String] Namespace associated with this application
# @!attribute [r] git_url
#   @return [String] {http://git-scm.com/ Git} URL to access code for this application
# @!attribute [r] app_url
#   @return [String] The FQDN to access this application
# @!attribute [r] ssh_url
#   @return [String] username and FQDN that can be used to ssh into the primary application gear
# @!attribute [r] gear_profile
#   @return [String] The default gear profile that will be used to create gears for this application
# @!attribute [r] scalable
#   @return [Boolean] Indicates if the application is scalable (uses multiple gears) or not (all cartridges on the same gear)
# @!attribute [r] health_check_path
#   @return [String] HTTP URI which can be used to determine if the application is up and serving requests.
# @!attribute [r] building_with
#   @return [String] Name of cartridge used to initiate CI builds
# @!attribute [r] building_app
#   @return [String] Name of Application on which builds are run
# @!attribute [r] build_job_url
#   @return [String] URI on the CI server which represents the build job
# @!attribute [r] initial_git_url
#   @return [String] URI which was used to initialize the GIT repository for this application
# @!attribute [r] auto_deploy
#   @return [Boolean] Boolean indicating whether auto deploy is enabled for this application
# @!attribute [r] deployment_branch
#   @return [String] The HEAD of the branch to deploy from by default
# @!attribute [r] keep_deployments
#   @return [Integer] The number of deployments to keep around including the active one
# @!attribute [r] deployment_type
#   @return [String] deployment_type The deployment type (binary|git)
# @!attribute [r] scale_min
#   @return [Integer] Minimum number of gears used by the web framework cartridge (Scalable applications only)
# @!attribute [r] scale_max
#   @return [Integer] Maximum number of gears used by the web framework cartridge (Scalable applications only)
class RestApplication10 < OpenShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url,
   :building_with, :building_app, :build_job_url, :gear_profile, :scalable, :health_check_path, :scale_min, :scale_max, :cartridges,
   :auto_deploy, :deployment_branch, :keep_deployments, :deployment_type

  def initialize(app, url, nolinks=false, applications=nil)
    self.embedded = {}

    self.name = app.name
    self.creation_time = app.created_at
    self.uuid = app._id
    self.aliases = app.aliases.map{ |a| a.fqdn }
    self.gear_count = app.gears.count
    self.domain_id = app.domain_namespace

    self.gear_profile = app.default_gear_size
    self.scalable = app.scalable

    if app.scalable
      self.scale_min, self.scale_max = app.get_app_scaling_limits
    else
      self.scale_min, self.scale_max = [1, 1]
    end

    if ssh_uri = app.ssh_uri.presence
      self.git_url = "ssh://#{ssh_uri}/~/git/#{@name}.git/"
      self.ssh_url = "ssh://#{ssh_uri}"
    end
    self.app_url = app.app_url
    self.health_check_path = app.health_check_path

    self.building_with = nil
    self.building_app = nil
    self.build_job_url = nil

    self.auto_deploy = app.config['auto_deploy']
    self.deployment_branch = app.config['deployment_branch']
    self.keep_deployments = app.config['keep_deployments']
    self.deployment_type = app.config['deployment_type']

    app.component_instances.each do |component_instance|
      cart = component_instance.cartridge

      # add the builder properties if this is a builder component
      if cart.is_ci_builder?
        self.building_with = cart.name
        self.build_job_url = component_instance.component_properties["job_url"]

        # adding the job_url and "info" property for backward compatibility
        self.embedded[cart.name] = component_instance.component_properties
        self.embedded[cart.name]["info"] = "Job URL: #{component_instance.component_properties['job_url']}"
      elsif cart.is_web_framework?
        self.framework = cart.name
      else
        self.embedded[cart.name] = component_instance.component_properties

        # if the component has a connection_url property, add it as "info" for backward compatibility
        # make sure it is a hash, because copy-pasting the app document in mongo (using rockmongo UI) can convert hashes into arrays
        if component_instance.component_properties.is_a?(Hash) and component_instance.component_properties.has_key?("connection_url")
          self.embedded[cart.name]["info"] = "Connection URL: #{component_instance.component_properties['connection_url']}"
        end
      end
    end

    #TODO this is way too inefficient.  Adding a bit of a hack to not have to call this all the time.
    app.domain.env_vars.each do |env_var|
      if env_var['key'] == 'JENKINS_URL'
        apps = applications || app.domain.applications
        apps.each do |domain_app|
          domain_app.component_instances.each do |component_instance|
            if component_instance.cartridge.is_ci_server?
              self.building_app = domain_app.name
              break
            end
          end
        end
        break
      end
    end

    unless nolinks
      carts = CartridgeCache.other_names

      self.links = {
        "GET" => Link.new("Get application", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
        "GET_DESCRIPTOR" => Link.new("Get application descriptor", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/descriptor")),
        "GET_GEARS" => Link.new("Get application gears", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gears")),
        "GET_GEAR_GROUPS" => Link.new("Get application gear groups", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gear_groups")),
        "START" => Link.new("Start application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "start")
        ]),
        "STOP" => Link.new("Stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "stop")
        ]),
        "RESTART" => Link.new("Restart application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "restart")
        ]),
        "FORCE_STOP" => Link.new("Force stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "force-stop")
        ]),
        "ADD_ALIAS" => Link.new("Add application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "add-alias"),
          Param.new("alias", "string", "The server alias for the application")
        ]),
        "REMOVE_ALIAS" => Link.new("Remove application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "remove-alias"),
          Param.new("alias", "string", "The application alias to be removed")
        ]),
        "SCALE_UP" => Link.new("Scale up application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-up")
        ]),
        "SCALE_DOWN" => Link.new("Scale down application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-down")
        ]),
        "TIDY" => Link.new("Tidy the application framework", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "tidy")
        ]),
        "RELOAD" => Link.new("Reload the application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "reload")
        ]),
        "THREAD_DUMP" => Link.new("Trigger thread dump", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "thread-dump")
        ]),
        "ADD_CARTRIDGE" => Link.new("Add embedded cartridge", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"),[
          Param.new("cartridge", "string", "Name of a cartridge.", carts)
        ]),
        "LIST_CARTRIDGES" => Link.new("List embedded cartridges", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges")),
        "DNS_RESOLVABLE" => Link.new("Resolve DNS", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/dns_resolvable")),
        "LIST_ENVIRONMENT_VARIABLES" => Link.new("List all environment variables", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/environment-variables")),
        "DEPLOY" => Link.new("Deploy the application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/deployments"), nil,[
          OptionalParam.new("ref", "string", "Git ref (tag, branch, commit id)", nil, "master"),
          OptionalParam.new("artifact_url", "string", "URL where the deployment artifact can be downloaded from"),
          OptionalParam.new("hot_deploy", "boolean", "Indicates whether this is a hot deployment", "true or false", false),
          OptionalParam.new("force_clean_build", "string", "Indicates whether a clean build should be performed", "true or false", false),
        ]),
        "ACTIVATE" => Link.new("Activate a specific deployment of the application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "activate"),
          Param.new("deployment_id", "string", "The deployment ID to activate the application")
        ]),
        "LIST_DEPLOYMENTS" => Link.new("List all deployments", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/deployments")),
        "UPDATE" => Link.new("Update application", "PUT", URI::join(url, "domains/#{@domain_id}/applications/#{@name}"), nil, [
          OptionalParam.new("auto_deploy", "boolean", "Indicates if OpenShift should build and deploy automatically whenever the user executes git push", [true, false]),
          OptionalParam.new("deployment_type", "string", "Indicates whether the app is setup for binary or git based deployments", ['git', 'binary']),
          OptionalParam.new("deployment_branch", "string", "Indicates which branch should trigger an automatic deployment, if automatic deployment is enabled."),
          OptionalParam.new("keep_deployments", "integer", "Indicates how many total deployments to preserve. Must be greater than 0"),
        ]),
        "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domains/#{@domain_id}/applications/#{@name}"))
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "application"
    super(options)
  end
end
