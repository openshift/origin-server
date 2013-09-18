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
  # URL: /domains/:domain_id/applications
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
  # URL: /domains/:domain_id/applications/:id
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
  # URL: /domains/:domain_id/applications
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
    app_name = params[:name].downcase if params[:name].presence
    features = []
    downloaded_cart_urls = []
    cart_params = [(params[:cartridges].presence || params[:cartridge].presence)].flatten
    cart_params.each do |c|
      if c.is_a?(Hash)
        if c[:name]
          features << c[:name]
        elsif c[:url]
          downloaded_cart_urls << c[:url]
        end
      else
        features << c
      end
    end

    user_env_vars = params[:environment_variables].presence
    Application.validate_user_env_variables(user_env_vars, true)

    init_git_url = params[:initial_git_url].presence
    if init_git_url
      repo_spec, _ = (OpenShift::Git.safe_clone_spec(init_git_url) rescue nil)
      return render_error(:unprocessable_entity, "Invalid initial git URL",
                          216, "initial_git_url") unless repo_spec
    end

    default_gear_size = params[:gear_size].presence || params[:gear_profile].presence || Rails.application.config.openshift[:default_gear_size]
    default_gear_size.downcase! if default_gear_size
    valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes & @domain.allowed_gear_sizes & @domain.owner.allowed_gear_sizes
    builder_id = nil

    if not authorized?(:create_application, @domain)
      if authorized?(:create_builder_application, @domain, {
            :cartridges => cart_params, 
            :gear_size => default_gear_size, 
            :valid_gear_sizes => valid_sizes,
            :domain_id => @domain._id
          })
        if scope = current_user.scopes.find{ |s| s.respond_to?(:builder_id) }
          builder_id = scope.builder_id
        end
      else
        authorize! :create_application, @domain # raise the proper error
      end
    end

    return render_error(:unprocessable_entity, "Application name is required and cannot be blank",
                        105, "name") if !app_name or app_name.empty?

    return render_error(:forbidden, "The owner of the domain #{@domain.namespace} has disabled all gear sizes from being created.  You will not be able to create an application in this domain.",
                        134) if valid_sizes.empty?

    return render_error(:unprocessable_entity, "The gear size '#{default_gear_size}' is not valid for this domain. Allowed sizes: #{valid_sizes.to_sentence}.",
                        134, "gear_profile") if default_gear_size and !valid_sizes.include?(default_gear_size)

    if Application.where(domain: @domain, canonical_name: app_name.downcase).present?
      return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "name")
    end

    Rails.logger.debug "Checking to see if user limit for number of apps has been reached"
    return render_error(:unprocessable_entity, 
                        "#{@cloud_user.login} has already reached the gear limit of #{@cloud_user.max_gears}",
                        104) if (@cloud_user.consumed_gears >= @cloud_user.max_gears)

    download_cartridges_enabled = Rails.application.config.openshift[:download_cartridges_enabled]
    limit = (Rails.application.config.downloaded_cartridges[:max_downloaded_carts_per_app] rescue 5) || 5
    carts = CartridgeCache.cartridge_names("web_framework")
    return render_error(:unprocessable_entity, "You may not specify more than #{limit} cartridges to be downloaded.",
                            109, "cartridge") if download_cartridges_enabled and downloaded_cart_urls.length > limit
    return render_error(:unprocessable_entity, "You must specify a cartridge. Valid values are (#{carts.join(', ')})",
                            109, "cartridge") if download_cartridges_enabled ? (downloaded_cart_urls.empty? and features.empty?) : features.empty?

    begin
      result = ResultIO.new
      scalable = get_bool(params[:scale])
      @application = Application.create_app(app_name, features, @domain, default_gear_size, scalable, result, [], init_git_url, request.headers['User-Agent'], downloaded_cart_urls, builder_id, user_env_vars)

    rescue OpenShift::UnfulfilledRequirementException => e
      return render_error(:unprocessable_entity, "Unable to create application for #{e.feature}", 109, "cartridges")
    rescue OpenShift::ApplicationValidationException => e
      messages = get_error_messages(e.app)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end
    @application.user_agent= request.headers['User-Agent']

    include_cartridges = (params[:include] == "cartridges")

    app = get_rest_application(@application, include_cartridges)
    render_success(:created, "application", app, "Application #{@application.name} was created.", result)
  end

  ##
  # Update an application
  #
  # URL: /domains/:domain_id/applications/:id
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

    return render_error(:unprocessable_entity, "Invalid number of deployments to keep: #{params[:keep_deployments]}. Keep deployments must be greater than 0.",
                        1, "keep_deployments") if keep_deployments and keep_deployments < 1

    return render_error(:unprocessable_entity, "Invalid deployment_branch: #{deployment_branch}. Deployment branches are limited to 256 characters",
                        1, "deployment_branch") if deployment_branch and deployment_branch.length > 256

    begin
      @application.config['auto_deploy'] = auto_deploy if !auto_deploy.nil?
      @application.config['deployment_branch'] = deployment_branch if deployment_branch
      @application.config['keep_deployments'] = keep_deployments if keep_deployments
      @application.config['deployment_type'] = deployment_type if deployment_type
      result = @application.update_configuration
    rescue OpenShift::ApplicationValidationException => e
      messages = get_error_messages(e.app)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end

    include_cartridges = (params[:include] == "cartridges")
    app = get_rest_application(@application, include_cartridges)
    render_success(:ok, "application", app, "Application #{@application.name} was updated.", result)
  end

  ##
  # Delete an application
  #
  # URL: /domains/:domain_id/applications/:id
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
