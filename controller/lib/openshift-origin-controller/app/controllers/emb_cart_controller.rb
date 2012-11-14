class EmbCartController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper

  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]

    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "LIST_APP_CARTRIDGES") if !domain || !domain.hasAccess?(@cloud_user)

    Rails.logger.debug "Getting cartridges for application #{id} under domain #{domain_id}"
    application = get_application(id)
    return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'",
                        101, "LIST_APP_CARTRIDGES") unless application

    cartridges = Array.new
    cartridges.push(RestCartridge11.new("standalone", application.framework, application, get_url, nil, nolinks)) if $requested_api_version != 1.0

    application.embedded.each_key do |key|
      if $requested_api_version == 1.0
        cartridge = RestCartridge10.new("embedded", key, application, get_url, nil, nolinks)
      else
        cartridge = RestCartridge11.new("embedded", key, application, get_url, nil, nolinks)
      end
      cartridges.push(cartridge)
    end if application.embedded
    render_success(:ok, "cartridges", cartridges, "LIST_APP_CARTRIDGES",
                   "Listing cartridges for application #{id} under domain #{domain_id}")
  end
  
  # GET /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    #include=status_messages
    status_messages = (params[:include] == "status_messages")
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "SHOW_APP_CARTRIDGE") if !domain || !domain.hasAccess?(@cloud_user)

    Rails.logger.debug "Getting cartridge #{id} for application #{application_id} under domain #{domain_id}"
    application = get_application(application_id)
    return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'",
                        101, "SHOW_APP_CARTRIDGE") if !application
   
    cartridge = nil 
    application.embedded.each do |key, value|
      if key == id
        app_status = application.status(key, false) if status_messages
        if $requested_api_version == 1.0
          cartridge = RestCartridge10.new("embedded", key, application, get_url, app_status, nolinks)
        else
          cartridge = RestCartridge11.new("embedded", key, application, get_url, app_status, nolinks)
        end
        break
      end
    end if application.embedded

    if !cartridge and id == application.framework and $requested_api_version != 1.0
      app_status = application.status(application.framework, false) if status_messages
      app_status.each do |gear_status|
        #FIXME: work around until cartridge status hook provides better interface
        message = "#{application.framework} is started."
        message = "#{application.framework} is stopped or inaccessible." if gear_status['message'].match(/(stopped)|(inaccessible)/)
        gear_status['message'] = message
      end if app_status
      cartridge = RestCartridge11.new("standalone", application.framework, application, get_url, app_status, nolinks)
    end
    return render_success(:ok, "cartridge", cartridge, "SHOW_APP_CARTRIDGE",
           "Showing cartridge #{id} for application #{application_id} under domain #{domain_id}") if cartridge

    render_error(:not_found, "Cartridge #{id} not found for application #{application_id}",
                 129, "SHOW_APP_CARTRIDGE")
  end

  # POST /domains/[domain_id]/applications/[application_id]/cartridges
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]

    name = params[:name]
    # :cartridge param is deprecated because it isn't consistent with
    # the rest of the apis which take :name. Leave it here because
    # some tools may still use it
    name = params[:cartridge] unless name
    colocate_with = params[:colocate_with]

    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "EMBED_CARTRIDGE") if !domain || !domain.hasAccess?(@cloud_user)

    application = get_application(id)
    return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'",
                        101, "EMBED_CARTRIDGE") unless application

    begin
      #container = OpenShift::ApplicationContainerProxy.find_available(application.server_identity)
      container = OpenShift::ApplicationContainerProxy.find_available(nil)
      if not check_cartridge_type(name, container, "embedded")
        carts = get_cached("cart_list_embedded", :expires_in => 21600.seconds) {
                           Application.get_available_cartridges("embedded")}
        return render_error(:bad_request, "Invalid cartridge. Valid values are (#{carts.join(', ')})",
                            109, "EMBED_CARTRIDGE", "cartridge")
      end
    rescue Exception => e
      return render_exception(e, "EMBED_CARTRIDGE")
    end
    
    #TODO: Need a proper method to let us know if cart will get its own gear
    if application.scalable && colocate_with.nil? && (@cloud_user.consumed_gears >= @cloud_user.max_gears) && name != 'jenkins-client-1.4'
      return render_error(:unprocessable_entity, "#{@cloud_user.login} has already reached the gear limit of #{@cloud_user.max_gears}",
                          104, "EMBED_CARTRIDGE")
    end

    cart_create_reply = ""
    begin
      application.add_group_override(name, colocate_with) if colocate_with
      cart_create_reply = application.add_dependency(name)
    rescue Exception => e
      return render_exception(e, "EMBED_CARTRIDGE")
    end

    application = get_application(id)

    application.embedded.each do |key, value|
      if key == name
        if $requested_api_version == 1.0
          cartridge = RestCartridge10.new("embedded", key, application, get_url, nil, nolinks)
        else
          cartridge = RestCartridge11.new("embedded", key, application, get_url, nil, nolinks)
        end
        messages = []
        log_msg = "Added #{name} to application #{id}"
        messages.push(Message.new(:info, log_msg))
        messages.push(Message.new(:info, cart_create_reply.resultIO.string, 0, :result))
        messages.push(Message.new(:info, cart_create_reply.appInfoIO.string, 0, :appinfo))
        return render_success(:created, "cartridge", cartridge, "EMBED_CARTRIDGE", log_msg, nil, nil, messages)

      end
    end if application.embedded
    render_error(:internal_server_error, "Cartridge #{name} not embedded within application #{id}", nil, "EMBED_CARTRIDGE")
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:id]

    domain = Domain.get(@cloud_user, domain_id)
    return render_format_error(:not_found, "Domain #{domain_id} not found", 127,
                               "REMOVE_CARTRIDGE") if !domain || !domain.hasAccess?(@cloud_user)

    application = get_application(id)
    return render_format_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'",
                               101, "REMOVE_CARTRIDGE") unless application
    
    return render_format_error(:bad_request, "Cartridge #{cartridge} not embedded within application #{id}",
                               129, "REMOVE_CARTRIDGE") if !application.embedded or !application.embedded.has_key?(cartridge)

    begin
      Rails.logger.debug "Removing #{cartridge} from application #{id}"
      application.remove_dependency(cartridge)
    rescue Exception => e
      return render_format_exception(e, "REMOVE_CARTRIDGE")
    end
      
    application = get_application(id)
    if $requested_api_version == 1.0
      app = RestApplication10.new(application, get_url, nolinks)
    else
      app = RestApplication12.new(application, get_url, nolinks)
    end
    render_format_success(:ok, "application", app, "REMOVE_CARTRIDGE", "Removed #{cartridge} from application #{id}", true)
  end

  # UPDATE /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def update
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    cartridge_name = params[:id]
    additional_storage = params[:additional_storage]
    scales_from = params[:scales_from]
    scales_to = params[:scales_to]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "UPDATE_CARTRIDGE") if !domain || !domain.hasAccess?(@cloud_user)

    app = get_application(app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "UPDATE_CARTRIDGE") unless app
                        
    storage_map = {}
    app.comp_instance_map.values.each do |cinst|
      if cinst.parent_cart_name==cartridge_name
        group_name = cinst.group_instance_name
        storage_map[group_name] = [] unless storage_map.has_key?(group_name)
        storage_map[group_name] << cinst
      end
    end
    return render_error(:not_found, "Cartridge '#{cartridge_name}' for application '#{app_id}' not found",
                        163, "UPDATE_CARTRIDGE") unless storage_map.keys.length>0
                
    #only update attributes that are specified                  
    if additional_storage
      max_storage = @cloud_user.capabilities['max_storage_per_gear']
      return render_format_error(:forbidden, "User is not allowed to change storage quota", 164,
                                 "UPDATE_CARTRIDGE") unless max_storage
      num_storage = nil
      begin 
        num_storage = Integer(additional_storage)
      rescue => e
        return render_format_error(:unprocessable_entity, "Invalid storage value provided.", 165, "UPDATE_CARTRIDGE", "additional_storage")
      end
      begin
        storage_map.each do |group_name, component_instance_list|
          each_component_share = (Float(num_storage))/component_instance_list.length
          ginst = app.group_instance_map[group_name]
          component_instance_list.each { |cinst| cinst.set_additional_quota(app, each_component_share) }
        end
        app.save
      rescue Exception => e
        return render_format_exception(e, "UPDATE_CARTRIDGE")
      end             
    end

    if scales_from or scales_to
      begin
        app.set_user_min_max(storage_map, scales_from, scales_to)
      rescue OpenShift::UserException=>e
        return render_format_error(:unprocessable_entity, e.message, 168,
                         "UPDATE_CARTRIDGE") 
      rescue Exception=>e
        return render_format_error(:forbidden, e.message, 164,
                         "UPDATE_CARTRIDGE") 
      end
    end
    cart_type = cartridge_name==app.framework ? "standalone" : "embedded"
    if $requested_api_version == 1.0
      cartridge = RestCartridge10.new(cart_type, cartridge_name, app, get_url, nil, nolinks)
    else
      cartridge = RestCartridge11.new(cart_type, cartridge_name, app, get_url, nil, nolinks)
    end
    render_format_success(:ok, "cartridge", cartridge, "UPDATE_CARTRIDGE", "Updated #{cartridge_name} from application #{app_id}", true)
  end
end
