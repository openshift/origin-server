##
#@api REST
# Application CRUD REST API
class ApplicationsController < BaseController
  include RestModelHelper
  #before_filter :get_domain, :only => :create
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
    apps =
      case params[:owner]
      when "@self" then Application.includes(:domain).accessible(current_user).where(owner: current_user)
      when nil     then Application.includes(:domain).accessible(current_user)
      else return render_error(:bad_request, "Only @self is supported for the 'owner' argument.")
      end.where(by).sort_by{ |a| a.name }.map { |app| get_rest_application(app, include_cartridges) }
    Domain.find_by(canonical_namespace: domain_id.downcase) if apps.empty? && domain_id.present? # check for a missing domain

    @analytics_tracker.track_event('apps_list', nil, nil, {'domain_namespace' => domain_id})

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
    available = get_bool(params[:ha])
    default_gear_size = (params[:gear_size].presence || params[:gear_profile].presence || Rails.application.config.openshift[:default_gear_size]).downcase
    config = (params[:config].is_a?(Hash) and params[:config])

    # Use the region user has specified, use default region if specified else leave as nil
    region_name = params[:region].presence
    region = nil
    if region_name
      unless Rails.application.config.openshift[:allow_region_selection] then
        raise OpenShift::UserException.new("Specifying a region on application creation has been disabled. A region may be automatically assigned for you.")
      end
      region = Region.find_by(name: region_name) rescue nil
      if region.nil?
        available_regions = Region.where({}).collect{|r| r.name}
        raise OpenShift::UserException.new(available_regions.empty? ? "Server does not support explicit regions." : "Could not find region '#{region_name}'. Available regions are: #{available_regions.join(", ")}.")
      end
    elsif Rails.application.config.openshift[:default_region_name].present?
      region = Region.find_by(name: Rails.application.config.openshift[:default_region_name]) rescue nil
      if region.nil?
        Rails.logger.warn "The default region #{Rails.application.config.openshift[:default_region_name]} does not exist. Proceeding to create app without specific region"
      else
        region_name = region.name
      end
    end

    region_id = region ? region.id : nil

    if OpenShift::ApplicationContainerProxy.blacklisted? app_name
      return render_error(:forbidden, "Application name is not allowed. Please choose another.", 105)
    end

    if init_git_url = String(params[:initial_git_url]).presence
      repo_spec, commit = (OpenShift::Git.safe_clone_spec(init_git_url, OpenShift::Git::ALLOWED_SCHEMES, params[:initial_git_branch].presence) rescue nil)
      if repo_spec.blank?
        return render_error(:unprocessable_entity, "Invalid initial git URL",
                            216, "initial_git_url")
      end
      init_git_url = [repo_spec, commit].compact.join('#')
    elsif params[:initial_git_branch].presence
      return render_error(:unprocessable_entity, "Initial git branch cannot be specified without specifying initial git URL",
                            nil, "initial_git_branch")
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
      return render_error(:unprocessable_entity, "Each cartridge must be specified by a name, or a JSON hash with a 'name' or 'url' key.", 109, 'cartridge') unless params[:advanced]
    end

    find_or_create_domain!

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

    @domain.validate_gear_sizes!([default_gear_size], "gear_size")
    @domain.validate_gear_sizes!(specs.map{ |f| f[:gear_size] }.compact.uniq, "cartridges")

    if available
      raise OpenShift::UserException.new("This feature ('High Availability') is currently disabled. Enable it in OpenShift's config options.") if not Rails.configuration.openshift[:allow_ha_applications]
      raise OpenShift::UserException.new("'High Availability' is not an allowed feature for the account ('#{@domain.owner.login}')") if not @domain.owner.ha
    end

    app = Application.new(
      domain: @domain,
      name: app_name,
      default_gear_size: default_gear_size,
      scalable: scalable || available,
      ha: available,
      builder_id: builder_id,
      user_agent: request.user_agent,
      init_git_url: init_git_url,
      region_id: region_id
    )
    if config.present?
      app.config.each do |k, default|
        if !(v = config[k]).nil?
          app.config[k] =
            case default
            when Integer then (Integer(v) rescue default)
            when FalseClass, TrueClass then (get_bool(v) rescue v)
            else v.to_s
            end
        end
      end
    end
    app.analytics['user_agent'] = request.user_agent
    @application = app

    raise OpenShift::ApplicationValidationException.new(app) unless app.valid?

    if (@domain.owner.consumed_gears >= @domain.owner.max_gears)
      return render_error(:unprocessable_entity,
                          "#{@cloud_user.login} has already reached the gear limit of #{@domain.owner.max_gears}",
                          104)
    end

    user_env_vars = params[:environment_variables].presence
    Application.validate_user_env_variables(user_env_vars, true)

    cartridges = CartridgeCache.find_and_download_cartridges(specs, "cartridge", true)

    if (cartridges.map(&:additional_gear_storage).compact.map(&:to_i).max || 0) > @domain.owner.max_storage
      return render_error(:unprocessable_entity,
                          "#{@cloud_user.login} has requested more additional gear storage than allowed (max: #{@domain.owner.max_storage} GB)",
                          166)
    end

    frameworks = cartridges.select(&:is_web_framework?)
    if frameworks.empty? && !params[:advanced]
      include_obsolete = builder_id or Rails.configuration.openshift[:allow_obsolete_cartridges]
      framework_carts = CartridgeCache.web_framework_names(include_obsolete).presence or
        raise OpenShift::UserException.new("Unable to determine list of available cartridges. Please try again and contact support if the issue persists.", 109, "cartridges")
      raise OpenShift::UserException.new("An application must contain one web cartridge. None of the specified cartridges is a web cartridge. " \
                                         "Please include one of the following cartridges: #{framework_carts.to_sentence} or supply a valid url to a custom " \
                                         "web_framework cartridge.", 109, "cartridge")
    end

    if !Rails.configuration.openshift[:allow_obsolete_cartridges] && !builder_id && (obsolete = cartridges.select{ |c| !c.singleton? && c.obsolete }.presence)
      raise OpenShift::UserException.new("The following cartridges are no longer available: #{obsolete.map(&:name).to_sentence}", 109, "cartridges")
    end

    result = app.add_initial_cartridges(cartridges, init_git_url, user_env_vars)

    @analytics_tracker.identify(@cloud_user.reload)
    analytics_props = {}
    if region_name
      analytics_props = {'region' => region_name}
    end
    @analytics_tracker.track_event('app_create', @domain, @application, analytics_props)

    include_cartridges = (params[:include] == "cartridges")
    rest_app = get_rest_application(app, include_cartridges)

    render_success(:created, "application", rest_app, "Application #{app.name} was created.", result)

  rescue Moped::Errors::OperationFailure => e
    return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "name") if [11000, 11001].include?(e.details['code'])
    raise

  rescue OpenShift::UnfulfilledRequirementException => e
    return render_error(:unprocessable_entity, "Unable to create application: #{e.message}", 109, "cartridges")
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

    new_config = {}
    new_config['auto_deploy'] = auto_deploy unless auto_deploy.nil?
    new_config['deployment_branch'] = deployment_branch unless deployment_branch.nil?
    new_config['keep_deployments'] = keep_deployments unless keep_deployments.nil?
    new_config['deployment_type'] = deployment_type unless deployment_type.nil?
    result = @application.update_configuration(new_config)

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

    cartridges = @application.cartridges.map(&:name).join(', ')
    result = @application.destroy_app

    @analytics_tracker.identify(@cloud_user.reload)
    @analytics_tracker.track_event('app_delete', @domain, @application, {'cartridges' => cartridges})

    status = requested_api_version <= 1.4 ? :no_content : :ok
    return render_success(status, nil, nil, "Application #{id} is deleted.", result)
  end
end
