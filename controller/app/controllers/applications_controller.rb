##
#@api REST
# Application CRUD REST API
class ApplicationsController < BaseController
  include RestModelHelper
  before_filter :get_domain
  before_filter :get_application, :only => [:show, :destroy, :update]
  ##
  # List all applications
  # 
  # URL: /domains/:domain_id/applications
  # @param [String] include Comma seperated list of sub-objects to include in reply. Only "cartridges" is supported at the moment.
  #
  # Action: GET
  # @return [RestReply<Array<RestApplication>>] List of applications within the domain
  def index
    include_cartridges = (params[:include] == "cartridges")
    apps = @domain.applications
    rest_apps = apps.map! { |application| get_rest_application(application, include_cartridges, apps) }
    render_success(:ok, "applications", rest_apps, "Found #{rest_apps.length} applications for domain '#{@domain.namespace}'")
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
    app_name = params[:name].downcase if params[:name]
    features = []
    downloaded_cart_urls = []
    cart_params = [(params[:cartridges] || params[:cartridge])].flatten
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
    init_git_url = params[:initial_git_url]
    
    return render_error(:unprocessable_entity, "Invalid initial git URL",
                        216, "initial_git_url") if init_git_url and (not init_git_url =~ /^#{URI::regexp}$/)
                        
    default_gear_size = params[:gear_profile]
    default_gear_size.downcase! if default_gear_size

    return render_error(:unprocessable_entity, "Application name is required and cannot be blank",
                        105, "name") if !app_name or app_name.empty?

    valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes(@domain.owner)
    return render_error(:unprocessable_entity, "Invalid size: #{default_gear_size}. Acceptable values are #{valid_sizes.join(",")}",
                        134, "gear_profile") if default_gear_size and !valid_sizes.include?(default_gear_size)

    if Application.where(domain: @domain, canonical_name: app_name.downcase).count > 0
      return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "name")
    end

    Rails.logger.debug "Checking to see if user limit for number of apps has been reached"
    return render_error(:unprocessable_entity, "#{@cloud_user.login} has already reached the gear limit of #{@cloud_user.max_gears}",
                        104) if (@cloud_user.consumed_gears >= @cloud_user.max_gears)

    download_cartridges_enabled = Rails.application.config.openshift[:download_cartridges_enabled]
    limit = (Rails.application.config.downloaded_cartridges[:max_downloaded_carts_per_app] rescue 5) || 5
    carts = CartridgeCache.cartridge_names("web_framework")
    return render_error(:unprocessable_entity, "You may not specify more than #{limit} cartridges to be downloaded.",
                            109, "cartridge") if download_cartridges_enabled and downloaded_cart_urls.length > limit
    return render_error(:unprocessable_entity, "You must specify a cartridge. Valid values are (#{carts.join(', ')})",
                            109, "cartridge") if download_cartridges_enabled ? (downloaded_cart_urls.empty? and features.empty?) : features.empty?

    begin
      app_creation_result = ResultIO.new
      scalable = get_bool(params[:scale])
      application = Application.create_app(app_name, features, @domain, default_gear_size, scalable, app_creation_result, [], init_git_url, request.headers['User-Agent'], downloaded_cart_urls)

      @application_name = application.name
      @application_uuid = application.uuid
    rescue OpenShift::UnfulfilledRequirementException => e
      return render_error(:unprocessable_entity, "Unable to create application for #{e.feature}", 109, "cartridges")
    rescue OpenShift::ApplicationValidationException => e
      messages = get_error_messages(e.app)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code, e.field)
    rescue Exception => e
      return render_exception(e)  
    end
    application.user_agent= request.headers['User-Agent']
    
    current_ip = application.group_instances.first.gears.first.get_public_ip_address rescue nil
    include_cartridges = (params[:include] == "cartridges")
    
    app = get_rest_application(application, include_cartridges)
    reply = new_rest_reply(:created, "application", app)
  
    messages = []
    log_msg = "Application #{application.name} was created."
    messages.push(Message.new(:info, log_msg))
    messages.push(Message.new(:info, "#{current_ip}", 0, "current_ip")) unless !current_ip or current_ip.empty?

    messages.push(Message.new(:info, app_creation_result.resultIO.string, 0, :result)) if app_creation_result
    render_success(:created, "application", app, log_msg, nil, nil, messages)
  end
  
  ##
  # Create a new application
  # 
  # URL: /domains/:domain_id/applications/:id
  #
  # Action: DELETE
  def destroy
    id = params[:id].downcase if params[:id] 
    begin
      @application.destroy_app
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    end
    
    render_success(:no_content, nil, nil, "Application #{id} is deleted.", true) 
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "APPLICATION"
  end
end
