##
#@api REST
# Application CRUD REST API
class ApplicationsController < BaseController
  include RestModelHelper

  ##
  # List all applications
  # 
  # URL: /domains/:domain_id/applications
  # @param [String] include Comma seperated list of sub-objects to include in reply. Only "cartridges" is supported at the moment.
  #
  # Action: GET
  # @return [RestReply<Array<RestApplication>>] List of applications within the domain
  def index
    domain_id = params[:domain_id]
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "LIST_APPLICATIONS")
    end

    include_cartridges = (params[:include] == "cartridges")
    apps = domain.applications
    rest_apps = apps.map! { |application| get_rest_application(application, domain, include_cartridges, apps) }
    render_success(:ok, "applications", rest_apps, "LIST_APPLICATIONS", "Found #{rest_apps.length} applications for domain '#{domain_id}'")
  end
  
  ##
  # Retrieve a specific application
  # 
  # URL: /domains/:domain_id/applications/:id
  #
  # Action: GET
  # @return [RestReply<RestApplication>] Application object
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "SHOW_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      include_cartridges = (params[:include] == "cartridges")
      
      @application_name = application.name
      @application_uuid = application.uuid
      render_success(:ok, "application", get_rest_application(application, domain, include_cartridges), "SHOW_APPLICATION", "Application '#{id}' found")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found", 101, "SHOW_APPLICATION")
    end
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
    domain_id = params[:domain_id]
    app_name = params[:name]
    features = Array(params[:cartridges] || params[:cartridge]).map{ |c| c.is_a?(Hash) ? c[:name] : c }
    scalable = get_bool(params[:scale])
    init_git_url = params[:initial_git_url]
    default_gear_size = params[:gear_profile]
    default_gear_size.downcase! if default_gear_size

    begin
      # Use strong consistency to avoid race condition creating domain and app in succession
      domain = Domain.with(consistency: :strong).find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127,"ADD_APPLICATION")
    end

    return render_error(:unprocessable_entity, "Application name is required and cannot be blank",
                        105, "ADD_APPLICATION", "name") if !app_name or app_name.empty?

    valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes(domain.owner)
    return render_error(:unprocessable_entity, "Invalid size: #{default_gear_size}. Acceptable values are #{valid_sizes.join(",")}",
                        134, "ADD_APPLICATION", "gear_profile") if default_gear_size and !valid_sizes.include?(default_gear_size)

    if Application.where(domain: domain, canonical_name: app_name.downcase).count > 0
      return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "ADD_APPLICATION", "name")
    end

    Rails.logger.debug "Checking to see if user limit for number of apps has been reached"
    return render_error(:unprocessable_entity, "#{@cloud_user.login} has already reached the gear limit of #{@cloud_user.max_gears}",
                        104, "ADD_APPLICATION") if (@cloud_user.consumed_gears >= @cloud_user.max_gears)

    return render_error(:unprocessable_entity, "You must specify a cartridge. Valid values are (#{carts.join(', ')})",
                            109, "ADD_APPLICATION", "cartridge") if features.nil?

    begin
      framework_carts = CartridgeCache.cartridge_names("web_framework")
      return render_error(:unprocessable_entity, "You must specify a cartridge. Valid values are (#{framework_carts.join(', ')})", 109, "ADD_APPLICATION", "cartridge") if features.nil?
      framework_cartridges = []
      other_cartridges = []
      features.each do |cart|
        framework_cartridges.push(cart) unless not framework_carts.include?(cart)
        other_cartridges.push(cart) unless framework_carts.include?(cart)
      end
      if framework_carts.empty?
        return render_error(:unprocessable_entity, "Unable to determine list of available cartridges.  If the problem persists please contact Red Hat support",
                          109, "ADD_APPLICATION", "cartridge")
      elsif framework_cartridges.empty?
        return render_error(:unprocessable_entity, "Each application must contain one web cartridge.  None of the specified cartridges #{features.to_sentence} is a web cartridge. Please include one of the following cartridges: #{framework_carts.to_sentence}.",
                          109, "ADD_APPLICATION", "cartridge")
      elsif framework_cartridges.length > 1
        return render_error(:unprocessable_entity, "Each application must contain only one web cartridge.  Please include a single web cartridge from this list: #{framework_carts.to_sentence}.",
                          109, "ADD_APPLICATION", "cartridge")
      end
      app_creation_result = ResultIO.new
      application = Application.create_app(app_name, features, domain, default_gear_size, scalable, app_creation_result, [], init_git_url, request.headers['User-Agent'])

      @application_name = application.name
      @application_uuid = application.uuid
    rescue OpenShift::UnfulfilledRequirementException => e
      return render_error(:unprocessable_entity, "Unable to create application for #{e.feature}", 109, "ADD_APPLICATION", "cartridge")
    rescue OpenShift::ApplicationValidationException => e
      messages = get_error_messages(e.app)
      return render_error(:unprocessable_entity, nil, nil, "ADD_APPLICATION", nil, nil, messages)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, 109, "ADD_APPLICATION", "cartridge")
    rescue Exception => e
      return render_error(:unprocessable_entity, e.message, 109, "ADD_APPLICATION", "cartridge")      
    end
    application.user_agent= request.headers['User-Agent']
    
    current_ip = application.group_instances.first.gears.first.get_public_ip_address rescue nil
    include_cartridges = (params[:include] == "cartridges")
    
    app = get_rest_application(application, domain, include_cartridges)
    reply = new_rest_reply(:created, "application", app)
  
    messages = []
    log_msg = "Application #{application.name} was created."
    messages.push(Message.new(:info, log_msg))
    messages.push(Message.new(:info, "#{current_ip}", 0, "current_ip")) unless !current_ip or current_ip.empty?

    messages.push(Message.new(:info, app_creation_result.resultIO.string, 0, :result)) if app_creation_result
    render_success(:created, "application", app, "ADD_APPLICATION", log_msg, nil, nil, messages)
  end
  
  ##
  # Create a new application
  # 
  # URL: /domains/:domain_id/applications/:id
  #
  # Action: DELETE
  def destroy
    domain_id = params[:domain_id]
    id = params[:id]    
    
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
      log_action("DELETE_APPLICATION", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DELETE_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application #{id} not found.", 101,"DELETE_APPLICATION")
    end
    
    # create tasks to delete gear groups
    begin
      application.destroy_app
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code, "DELETE_APPLICATION")
    end
    
    render_success(:no_content, nil, nil, "DELETE_APPLICATION", "Application #{id} is deleted.", true) 
  end
end
