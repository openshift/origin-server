##
#@api REST
# Application CRUD REST API
class ApplicationsController < BaseController
  include RestModelHelper
  before_filter :get_domain, :only => :create
  before_filter :get_application, :only => [:show, :destroy, :update]
  ##
  # List all applications
  #
  # URL: /applications
  # @param [String] include Comma separated list of sub-objects to include in reply. Only "cartridges" is supported at the moment.
  #
  # Action: GET
  # @return [RestReply<Array<RestApplication>>] List of applications within the domain
  def index
    include_cartridges = (params[:include] == "cartridges")
    domain_id = params[:domain_id].presence

    by = domain_id.present? ? {domain_namespace: Domain.check_name!(domain_id).downcase} : {}
    apps = Application.includes(:domain).accessible(current_user).where(by).map { |app| get_rest_application(app, include_cartridges) }
    Domain.find_by(canonical_namespace: domain_id.downcase) if apps.empty? && domain_id.present? # check for a missing domain

    render_success(:ok, "applications", apps, "Found #{apps.length} applications.")
  end

  ##
  # Retrieve a specific application
  #
  # Action: GET
  # @return [RestReply<RestApplication>] Application object
  def show
    include_cartridges = (params[:include] == "cartridges")
    render_success(:ok, "application", get_rest_application(@application, include_cartridges), "Application '#{@application.name}' found")
  end

  ##
  # Create a new application
  #
  # Action: POST
  # @param [String] name Application name
  # @param [Array<String>] cartridges List of cartridges to create the application with. There must be one web framework cartridge in the list.
  # @param [Boolean] scalable Create a scalable application. Defaults to false.
  # @param [String] init_git_url {http://git-scm.com Git} URI to use as a template when creating the application
  # @param [String] gear_profile Gear profile to use for gears when creating the application
  # @param [Array<Hash>] environment_variables One or more user environment variables for the application.
  #
  # @return [RestReply<RestApplication>] Application object
  def create
    app_name = String(params[:name]).downcase
    scalable = get_bool(params[:scale])
    default_gear_size = (params[:gear_size].presence || params[:gear_profile].presence || Rails.application.config.openshift[:default_gear_size]).downcase

    if init_git_url = String(params[:initial_git_url]).presence
      repo_spec, _ = (OpenShift::Git.safe_clone_spec(init_git_url) rescue nil)
      if repo_spec.blank?
        return render_error(:unprocessable_entity, "Invalid initial git URL",
                            216, "initial_git_url")
      end
    end

    specs = []
    [(params[:cartridges].presence || params[:cartridge].presence)].flatten.each do |c|
      if c.presence.is_a? String
        specs << {name: c}
      elsif c.is_a? Hash
        specs << c
      end
    end
    CartridgeInstance.check_cartridge_specifications!(specs)
    if not specs.all?{ |f| f[:name].present? ^ f[:url].present? }
      return render_error(:unprocessable_entity, "Each cartridge must be specified by a name, or a JSON hash with a 'name' or 'url' key.", 109, 'cartridge') 
    end

    builder_id = nil
    if not authorized?(:create_application, @domain)
      if authorized?(:create_builder_application, @domain, {
            :cartridges => specs,
            :domain_id => @domain._id
          })
        if scope = current_user.scopes.find{ |s| s.respond_to?(:builder_id) }
          builder_id = scope.builder_id
        end
      else
        authorize! :create_application, @domain # raise the proper error
      end
    end

    @domain.check_gear_sizes!([default_gear_size], "gear_size")
    @domain.check_gear_sizes!(specs.map{ |f| f[:gear_size] }.compact.uniq, "cartridges")

    app = Application.new(
      domain: @domain,
      name: app_name,
      default_gear_size: default_gear_size,
      scalable: scalable,
      builder_id: builder_id,
      user_agent: request.user_agent,
      init_git_url: init_git_url,
    )
    app.analytics['user_agent'] = request.user_agent
    @application = app

    raise OpenShift::ApplicationValidationException.new(app) unless app.valid?

    if (@cloud_user.consumed_gears >= @cloud_user.max_gears)
      return render_error(:unprocessable_entity,
                          "#{@cloud_user.login} has already reached the gear limit of #{@cloud_user.max_gears}",
                          104)
    end

    user_env_vars = params[:environment_variables].presence
    Application.validate_user_env_variables(user_env_vars, true)

    cartridges = CartridgeCache.find_and_download_cartridges(specs, "cartridge", true)

    frameworks = cartridges.select(&:is_web_framework?)
    if frameworks.empty?
      framework_carts = CartridgeCache.cartridge_names("web_framework").presence or
        raise OpenShift::UserException.new("Unable to determine list of available cartridges.  If the problem persists please contact Red Hat support.", 109, "cartridges")
      raise OpenShift::UserException.new("An application must contain one web cartridge.  None of the specified cartridges is a web cartridge. " \
                                         "Please include one of the following cartridges: #{framework_carts.to_sentence} or supply a valid url to a custom " \
                                         "web_framework cartridge.", 109, "cartridge")
    end

    result = app.add_initial_cartridges(cartridges, init_git_url, user_env_vars)

    include_cartridges = (params[:include] == "cartridges")
    rest_app = get_rest_application(app, include_cartridges)

    render_success(:created, "application", rest_app, "Application #{app.name} was created.", result)

  rescue Moped::Errors::OperationFailure => e
    return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "name") if [11000, 11001].include?(e.details['code'])
    raise

  rescue OpenShift::UnfulfilledRequirementException => e
    return render_error(:unprocessable_entity, "Unable to create application for #{e.feature}", 109, "cartridges")
  end

  ##
  # Update an application
  #
  # Action: PUT
  # @param [Boolean] auto_deploy Boolean indicating whether auto deploy is enabled (Default: true)
  # @param [String] deployment_branch The HEAD of the branch to deploy from by default (Default: master)
  # @param [Integer] keep_deployments The number of deployments to keep around including the active one (Default: 1)
  # @param [String] deployment_type The deployment type (binary|git) (Default: git)
  #
  # @return [RestReply<RestApplication>] Application object
  def update
    auto_deploy = get_bool(params[:auto_deploy]) if !params[:auto_deploy].nil?
    deployment_branch = params[:deployment_branch] if params[:deployment_branch].presence
    keep_deployments = params[:keep_deployments].to_i if params[:keep_deployments].presence
    deployment_type = params[:deployment_type].downcase if params[:deployment_type].presence

    authorize! :update_application, @application

    return render_error(:unprocessable_entity, "You must specify at least one of the following for an update: auto_deploy, deployment_branch, keep_deployments and/or deployment_type",
                        1, nil) if deployment_branch.nil? and auto_deploy.nil? and keep_deployments.nil? and deployment_type.nil?

    return render_error(:unprocessable_entity, "Invalid deployment type: #{deployment_type}. Acceptable values are: #{Application::DEPLOYMENT_TYPES.join(", ")}",
                        1, "deployment_type") if deployment_type and !Application::DEPLOYMENT_TYPES.include?(deployment_type)

    return render_error(:unprocessable_entity, "Invalid number of deployments to keep: #{params[:keep_deployments]}. Keep deployments must be greater than 0 and no greater than 1000.",
                        1, "keep_deployments") if keep_deployments and (keep_deployments < 1 or keep_deployments > 1000)

    return render_error(:unprocessable_entity, "Invalid deployment_branch: #{deployment_branch}. Deployment branches are limited to 256 characters",
                        1, "deployment_branch") if deployment_branch and deployment_branch.length > 256

    @application.config['auto_deploy'] = auto_deploy if !auto_deploy.nil?
    @application.config['deployment_branch'] = deployment_branch if deployment_branch
    @application.config['keep_deployments'] = keep_deployments if keep_deployments
    @application.config['deployment_type'] = deployment_type if deployment_type
    result = @application.update_configuration

    include_cartridges = (params[:include] == "cartridges")
    app = get_rest_application(@application, include_cartridges)
    render_success(:ok, "application", app, "Application #{@application.name} was updated.", result)
  end

  ##
  # Delete an application
  #
  # Action: DELETE
  def destroy
    if @application.quarantined
      return render_upgrade_in_progress
    end

    authorize! :destroy, @application

    id = params[:id].downcase if params[:id].presence

    result = @application.destroy_app

    status = requested_api_version <= 1.4 ? :no_content : :ok
    return render_success(status, nil, nil, "Application #{id} is deleted.", result)
  end
end
