class EmbCartController < BaseController
  include RestModelHelper

  # This is the regex for cartridge names
  # We need to ensure backward compatibility for fetches
  CART_NAME_COMPATIBILITY_REGEX = /\A([\w\-]+(-)([\d]+(\.[\d]+)*)+)\z/
    
  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_CARTRIDGES")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "LIST_APP_CARTRIDGES")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_CARTRIDGES")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      cartridges = get_application_rest_cartridges(application, domain) if application

      render_success(:ok, "cartridges", cartridges, "LIST_APP_CARTRIDGES", "Listing cartridges for application #{id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "LIST_APP_CARTRIDGES")
    end
  end

  # GET /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    status_messages = !params[:include].nil? and params[:include].split(",").include?("status_messages")

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_CARTRIDGE")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if application_id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_CARTRIDGE")
    end
    
    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if id !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge '#{id}' not found for application '#{application_id}'", 129, "SHOW_APP_CARTRIDGE")
    end
    
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_CARTRIDGE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_CARTRIDGE")
    end

    begin
      component_instance = application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(application, domain, component_instance, application.group_instances_with_scale, application.group_overrides, status_messages)
      return render_success(:ok, "cartridge", cartridge, "SHOW_APP_CARTRIDGE", "Showing cartridge #{id} for application #{application_id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Cartridge '#{id}' not found for application '#{application_id}'", 129, "SHOW_APP_CARTRIDGE")
    end
  end

  # POST /domains/[domain_id]/applications/[application_id]/cartridges
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    name = params[:name]

    # :cartridge param is deprecated because it isn't consistent with
    # the rest of the apis which take :name. Leave it here because
    # some tools may still use it
    name = params[:cartridge] if name.nil?
    colocate_with = params[:colocate_with]
    scales_from = Integer(params[:scales_from]) rescue nil
    scales_to = Integer(params[:scales_to]) rescue nil
    additional_storage = Integer(params[:additional_storage]) rescue nil

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "EMBED_CARTRIDGE")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "EMBED_CARTRIDGE")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "EMBED_CARTRIDGE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "EMBED_CARTRIDGE")
    end

    begin
      component_instance = application.component_instances.find_by(cartridge_name: name)
      if !component_instance.nil?
        return render_error(:unprocessable_entity, "Cartridge/Component/Feature #{name} already embedded in the application", 136, "EMBED_CARTRIDGE")
      end
    rescue
      #ignore
    end

    unless colocate_with.nil? or colocate_with.empty?
      begin
        colocate_component_instance = application.component_instances.find_by(cartridge_name: colocate_with)
        colocate_component_instance = colocate_component_instance.first if colocate_component_instance.class == Array
      rescue Mongoid::Errors::DocumentNotFound
        return render_error(:unprocessable_entity, "Invalid colocation specified. No component matches #{colocate_with}", 109, "EMBED_CARTRIDGE", "cartridge")      
      end
    end

    if scales_to and scales_from and scales_to != -1 and scales_from > scales_to
      return render_error(:unprocessable_entity, "Invalid scaling values provided. 'scales_from(#{scales_from})' cannot be greater than 'scales_to(#{scales_to})'.", 109, "EMBED_CARTRIDGE", "cartridge")      
    end

    begin
      group_overrides = []
      # Todo: REST API assumes cartridge only has one component
      cart = CartridgeCache.find_cartridge(name)

      if cart.nil?
        carts = CartridgeCache.cartridge_names("embedded")
        return render_error(:unprocessable_entity, "Invalid cartridge. Valid values are (#{carts.join(', ')})",
                            109, "EMBED_CARTRIDGE", "cartridge")
      end

      prof = cart.profile_for_feature(name)
      comp = prof.components.first
      comp_spec = {"cart" => cart.name, "comp" => comp.name}

      unless colocate_component_instance.nil?
        group_overrides << {"components" => [colocate_component_instance.to_hash, comp_spec]}
      end
      if !scales_to.nil? or !scales_from.nil? or !additional_storage.nil?
        group_override = {"components" => [comp_spec]}
        group_override["min_gears"] = scales_from unless scales_from.nil?
        group_override["max_gears"] = scales_to unless scales_to.nil?
        group_override["additional_filesystem_gb"] = additional_storage unless additional_storage.nil?
        group_overrides << group_override
      end

      cart_create_reply = application.add_features([name], group_overrides)

      component_instance = application.component_instances.find_by(cartridge_name: cart.name, component_name: comp.name)
      cartridge = get_rest_cartridge(application, domain, component_instance, application.group_instances_with_scale, application.group_overrides)

      messages = []
      log_msg = "Added #{name} to application #{id}"
      messages.push(Message.new(:info, log_msg))
      messages.push(Message.new(:info, cart_create_reply.resultIO.string, 0, :result))
      messages.push(Message.new(:info, cart_create_reply.appInfoIO.string, 0, :appinfo))
      return render_success(:created, "cartridge", cartridge, "EMBED_CARTRIDGE", log_msg, nil, nil, messages)
    rescue OpenShift::GearLimitReachedException => e
      return render_error(:unprocessable_entity, "Unable to add cartridge: #{e.message}", 104, "ADD_APPLICATION")
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, "Invalid cartridge. #{e.message}", 109, "EMBED_CARTRIDGE", "cartridge")
    end
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:id]

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "REMOVE_CARTRIDGE")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "REMOVE_CARTRIDGE")
    end
    
    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if cartridge !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{id}", 129, "REMOVE_CARTRIDGE")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "REMOVE_CARTRIDGE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "REMOVE_CARTRIDGE")
    end

    begin
      comp = application.component_instances.find_by(cartridge_name: cartridge)
      feature = application.get_feature(comp.cartridge_name, comp.component_name)  
      return render_error(:not_found, "Cartridge '#{cartridge}' not found for application '#{application.name}'", 101, "REMOVE_CARTRIDGE") if feature.nil?   
      application.remove_features([feature])

      app = if requested_api_version == 1.0
          RestApplication10.new(application, domain, get_url, nolinks)
        else
          RestApplication.new(application, domain, get_url, nolinks)
        end
      render_success(:no_content, nil, nil, "REMOVE_CARTRIDGE", "Removed #{cartridge} from application #{id}", true)
      #render_success(:ok, "application", app, "REMOVE_CARTRIDGE", "Removed #{cartridge} from application #{id}", true)
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code, "REMOVE_CARTRIDGE")
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code, "REMOVE_CARTRIDGE")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{id}", 129, "REMOVE_CARTRIDGE")
    end
  end

  # PUT /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def update
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    scales_from = Integer(params[:scales_from]) rescue nil
    scales_to = Integer(params[:scales_to]) rescue nil
    additional_storage = params[:additional_gear_storage]

    if scales_from.nil? and scales_to.nil? and additional_storage.nil?
      return render_error(:unprocessable_entity, "No update parameters specified.  Valid update parameters are: scales_from, scales_to, additional_gear_storage", 168, "PATCH_APP_CARTRIDGE") 
    end

    begin
      additional_storage = Integer(additional_storage) if additional_storage
    rescue Exception => e
      return render_error(:unprocessable_entity, "Invalid storage value provided: #{e.message}", 165, "PATCH_APP_CARTRIDGE", "additional_storage")
    end

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "PATCH_APP_CARTRIDGE")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if application_id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "PATCH_APP_CARTRIDGE")
    end
    
    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if id !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge #{id} not embedded within application #{application_id}", 129, "PATCH_APP_CARTRIDGE")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "PATCH_APP_CARTRIDGE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
 
      if !application.scalable and ((scales_from and scales_from != 1) or (scales_to and scales_to != 1 and scales_to != -1))
        return render_error(:unprocessable_entity, "Application '#{application_id}' is not scalable", 100, "PATCH_APP_CARTRIDGE", "name")
      end

      if scales_from and scales_from < 1
        return render_error(:unprocessable_entity, "Invalid scales_from factor #{scales_from} provided", 168, "PATCH_APP_CARTRIDGE", "scales_from") 
      end

      if scales_to and (scales_to == 0 or scales_to < -1)
        return render_error(:unprocessable_entity, "Invalid scales_to factor #{scales_to} provided", 168, "PATCH_APP_CARTRIDGE", "scales_to") 
      end

      if scales_to and scales_from and scales_to >= 1 and scales_to < scales_from
        return render_error(:unprocessable_entity, "Invalid scales_(from|to) factor provided", 168, "PATCH_APP_CARTRIDGE", "scales_to") 
      end

      begin
        component_instance = application.component_instances.find_by(cartridge_name: id)
      rescue Mongoid::Errors::DocumentNotFound
        return render_error(:not_found, "Cartridge #{id} not embedded within application #{application_id}", 129, "PATCH_APP_CARTRIDGE")
      end

      if component_instance.nil?
        return render_error(:unprocessable_entity, "Invalid cartridge #{id} for application #{application.name}", 168, "PATCH_APP_CARTRIDGE", "cartridge")
      end

      if component_instance.is_singleton?
        if scales_to and scales_to != 1
          return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_to")
        elsif scales_from and scales_from != 1
          return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_from")
        end
      end
      
      group_instance = application.group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]

      if scales_to and scales_from.nil? and scales_to >= 1 and scales_to < group_instance.min
        return render_error(:unprocessable_entity, "The scales_to factor currently provided cannot be lower than the scales_from factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "PATCH_APP_CARTRIDGE", "scales_to") 
      end

      if scales_from and scales_to.nil? and group_instance.max >= 1 and group_instance.max < scales_from
        return render_error(:unprocessable_entity, "The scales_from factor currently provided cannot be higher than the scales_to factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "PATCH_APP_CARTRIDGE", "scales_from") 
      end

      application.update_component_limits(component_instance, scales_from, scales_to, additional_storage)

      component_instance = application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(application, domain, component_instance, application.group_instances_with_scale, application.group_overrides)
      return render_success(:ok, "cartridge", cartridge, "SHOW_APP_CARTRIDGE", "Showing cartridge #{id} for application #{application_id} under domain #{domain_id}")
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code, "PATCH_APP_CARTRIDGE")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "PATCH_APP_CARTRIDGE")
    rescue Exception => e
      return render_exception(e, "PATCH_APP_CARTRIDGE")
    end

    return render_success(:ok, "cartridge", [], "PATCH_APP_CARTRIDGE", "")  
  end
end
