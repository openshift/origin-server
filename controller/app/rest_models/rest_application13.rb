class RestApplication13 < OpenShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url,
      :gear_profile, :scalable, :health_check_path, :building_with, :building_app, :build_job_url, :cartridges, :initial_git_url,
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

    if ssh_uri = app.ssh_uri.presence
      self.git_url = "ssh://#{ssh_uri}/~/git/#{@name}.git/"
      self.ssh_url = "ssh://#{ssh_uri}"
    end
    self.app_url = app.app_url
    self.health_check_path = app.health_check_path

    self.building_with = nil
    self.building_app = nil
    self.build_job_url = nil
    self.initial_git_url = app.init_git_url

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
      self.links = {
        "GET" => Link.new("Get application", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}")),
        "GET_DESCRIPTOR" => Link.new("Get application descriptor", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/descriptor")),
        #"GET_GEARS" => Link.new("Get application gears", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/gears")),
        "GET_GEAR_GROUPS" => Link.new("Get application gear groups", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/gear_groups")),
        "START" => Link.new("Start application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "start")
        ]),
        "STOP" => Link.new("Stop application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "stop")
        ]),
        "RESTART" => Link.new("Restart application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "restart")
        ]),
        "FORCE_STOP" => Link.new("Force stop application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "force-stop")
        ]),
        "ADD_ALIAS" => Link.new("Add application alias", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "add-alias"),
          Param.new("alias", "string", "The server alias for the application")
        ]),
        "REMOVE_ALIAS" => Link.new("Remove application alias", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "remove-alias"),
          Param.new("alias", "string", "The application alias to be removed", @aliases)
        ]),
        "SCALE_UP" => Link.new("Scale up application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-up")
        ]),
        "SCALE_DOWN" => Link.new("Scale down application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-down")
        ]),
        "TIDY" => Link.new("Tidy the application framework", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "tidy")
        ]),
        "RELOAD" => Link.new("Reload the application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "reload")
        ]),
        "THREAD_DUMP" => Link.new("Trigger thread dump", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "thread-dump")
        ]),
        "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domain/#{@domain_id}/application/#{@name}")),
        "ADD_CARTRIDGE" => Link.new("Add embedded cartridge", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/cartridges"),[
            Param.new("name", "string", "Name of a cartridge.")
          ],[
            OptionalParam.new("colocate_with", "string", "The component to colocate with", app.component_instances.map{|c| c.cartridge_name}),
            OptionalParam.new("scales_from", "integer", "Minimum number of gears to run the component on."),
            OptionalParam.new("scales_to", "integer", "Maximum number of gears to run the component on."),
            OptionalParam.new("additional_gear_storage", "integer", "Additional GB of space to request on all gears running this component."),
            OptionalParam.new("environment_variables", "array", "Add or Update application environment variables, e.g.:[{'name':'FOO', 'value':'123'}, {'name':'BAR', 'value':'abc'}]")
          ]
        ),
        "LIST_CARTRIDGES" => Link.new("List embedded cartridges", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/cartridges")),
        "DNS_RESOLVABLE" => Link.new("Resolve DNS", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/dns_resolvable")),
        "SET_UNSET_ENVIRONMENT_VARIABLES" => Link.new("Add/Update/Delete one or more environment variables", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/environment-variables"), nil, [
          OptionalParam.new("name", "string", "Name of the environment variable to add/update"),
          OptionalParam.new("value", "string", "Value of the environment variable"),
          OptionalParam.new("environment_variables", "array", "Add/Update/Delete application environment variables, e.g. Add/Update: [{'name':'FOO', 'value':'123'}, {'name':'BAR', 'value':'abc'}], Delete: [{'name':'FOO'}, {'name':'BAR'}]")
        ]),
        "LIST_ENVIRONMENT_VARIABLES" => Link.new("List all environment variables", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/environment-variables")),
        "DEPLOY" => Link.new("Deploy the application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/deployments"), nil,[
          OptionalParam.new("ref", "string", "Git ref (tag, branch, commit id)", nil, "master"),
          OptionalParam.new("artifact_url", "string", "URL where the deployment artifact can be downloaded from"),
          OptionalParam.new("hot_deploy", "boolean", "Indicates whether this is a hot deployment", "true or false", false),
          OptionalParam.new("force_clean_build", "string", "Indicates whether a clean build should be performed", "true or false", false),
        ]),
        "UPDATE_DEPLOYMENTS" => Link.new("Update deployments (Special permissions is required to update deployments)", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/deployments"), [
          Param.new("deployments", "array", "An array of deployments")]),
        "ACTIVATE" => Link.new("Activate a specific deployment of the application", "POST", URI::join(url, "domain/#{@domain_id}/application/#{@name}/events"), [
          Param.new("event", "string", "event", "activate"),
          Param.new("deployment_id", "string", "The deployment ID to activate the application")
        ]),
        "LIST_DEPLOYMENTS" => Link.new("List all deployments", "GET", URI::join(url, "domain/#{@domain_id}/application/#{@name}/deployments")),
        "UPDATE" => Link.new("Update application", "PUT", URI::join(url, "domain/#{@domain_id}/application/#{@name}"), nil, [
          OptionalParam.new("auto_deploy", "boolean", "Indicates if OpenShift should build and deploy automatically whenever the user executes git push", [true, false]),
          OptionalParam.new("deployment_type", "string", "Indicates whether the app is setup for binary or git based deployments", ['git', 'binary']),
          OptionalParam.new("deployment_branch", "string", "Indicates which branch should trigger an automatic deployment, if automatic deployment is enabled."),
          OptionalParam.new("keep_deployments", "integer", "Indicates how many total deployments to preserve. Must be greater than 0"),
        ]),
        "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domain/#{@domain_id}/application/#{@name}"))
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "application"
    super(options)
  end
end
