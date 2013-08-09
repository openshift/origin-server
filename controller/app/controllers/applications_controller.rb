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

    by = domain_id.present? ? {domain_namespace: Domain.check_name!(domain_id)} : {}
    apps = Application.includes(:domain).accessible(current_user).where(by).map { |app| get_rest_application(app, include_cartridges) }
    Domain.find_by(canonical_namespace: domain_id) if apps.empty? && domain_id.present? # check for a missing domain

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

    if init_git_url = params[:initial_git_url].presence
      repo_spec, _ = (OpenShift::Git.safe_clone_spec(init_git_url) rescue nil)
      return render_error(:unprocessable_entity, "Invalid initial git URL",
                          216, "initial_git_url") unless repo_spec
    end

    default_gear_size = params[:gear_size].presence || params[:gear_profile].presence || Rails.application.config.openshift[:default_gear_size]
    default_gear_size.downcase! if default_gear_size
    valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes & @domain.allowed_gear_sizes & @domain.owner.allowed_gear_sizes

    if not authorized?(:create_application, @domain)
      if authorized?(:create_builder_application, @domain, {
            :cartridges => cart_params, 
            :gear_size => default_gear_size, 
            :valid_gear_sizes => valid_sizes,
            :domain_id => @domain._id
          })
        # TODO: record this as a builder
      else
        authorize! :create_application, @domain # raise the proper error
      end
    end

    return render_error(:unprocessable_entity, "Application name is required and cannot be blank",
                        105, "name") if !app_name or app_name.empty?

    return render_error(:unprocessable_entity, "Invalid size: #{default_gear_size}. Acceptable values are: #{valid_sizes.join(",")}",
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
      @application = Application.create_app(app_name, features, @domain, default_gear_size, scalable, result, [], init_git_url, request.headers['User-Agent'], downloaded_cart_urls)

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
