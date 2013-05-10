class EmbCartController < BaseController
  include RestModelHelper
  before_filter :get_domain, :get_application

  # This is the regex for cartridge names
  # We need to ensure backward compatibility for fetches
  CART_NAME_COMPATIBILITY_REGEX = /\A([\w\-]+(-)([\d]+(\.[\d]+)*)+)\z/
    
  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    cartridges = get_application_rest_cartridges(@application) 
    render_success(:ok, "cartridges", cartridges, "Listing cartridges for application #{@application.name} under domain #{@domain.namespace}")
  end

  # GET /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def show
    id = params[:id]
    status_messages = !params[:include].nil? and params[:include].split(",").include?("status_messages")
    
    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if id !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge '#{id}' not found for application '#{@application.name}'", 129)
    end

    begin
      component_instance = @application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(@application, component_instance, @application.group_instances_with_scale, @application.group_overrides, status_messages)
      return render_success(:ok, "cartridge", cartridge, "Showing cartridge #{id} for application #{@application.name} under domain #{@domain.namespace}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Cartridge '#{id}' not found for application '#{@application.name}'", 129)
    end
  end

  # POST /domains/[domain_id]/applications/[application_id]/cartridges
  def create
    cart_param = params[:name]

    # :cartridge param is deprecated because it isn't consistent with
    # the rest of the apis which take :name. Leave it here because
    # some tools may still use it
    cart_param = params[:cartridge] if cart_param.nil?
    colocate_with = params[:colocate_with]
    scales_from = Integer(params[:scales_from]) rescue nil
    scales_to = Integer(params[:scales_to]) rescue nil
    additional_storage = Integer(params[:additional_storage]) rescue nil

    cart_urls = []
    if cart_param.is_a? Hash
      if cart_param[:name] and cart_param[:name].is_a? String
        name = cart_param[:name]
      elsif cart_param[:url]
        cart_urls << cart_param[:url]
        begin
          cmap = CartridgeCache.fetch_community_carts(cart_urls)
          flat_name = cmap.keys[0]
          name = "#{flat_name}-#{cmap[flat_name]["version"]}"
          @application.downloaded_cart_map.merge!(cmap)
          @application.save
        rescue Exception=>e
          return render_error(:unprocessable_entity, "Error in cartridge url - #{e.message}", 109)
        end
      end
    else
      name = cart_param
    end

    begin
      component_instance = @application.component_instances.find_by(cartridge_name: name)
      if !component_instance.nil?
        return render_error(:unprocessable_entity, "Cartridge/Component/Feature #{name} already embedded in the application", 136)
      end
    rescue
      #ignore
    end

    unless colocate_with.nil? or colocate_with.empty?
      begin
        colocate_component_instance = @application.component_instances.find_by(cartridge_name: colocate_with)
        colocate_component_instance = colocate_component_instance.first if colocate_component_instance.class == Array
      rescue Mongoid::Errors::DocumentNotFound
        return render_error(:unprocessable_entity, "Invalid colocation specified. No component matches #{colocate_with}", 109, "cartridge")      
      end
    end

    if scales_to and scales_from and scales_to != -1 and scales_from > scales_to
      return render_error(:unprocessable_entity, "Invalid scaling values provided. 'scales_from(#{scales_from})' cannot be greater than 'scales_to(#{scales_to})'.", 109, "cartridge")      
    end

    begin
      group_overrides = []
      # Todo: REST API assumes cartridge only has one component
      cart = CartridgeCache.find_cartridge(name, @application)

      if cart.nil?
        carts = CartridgeCache.cartridge_names("embedded", @application)
        return render_error(:unprocessable_entity, "Invalid cartridge. Valid values are (#{carts.join(', ')})",
                            109, "cartridge")
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

      cart_create_reply = @application.add_features([name], group_overrides)

      component_instance = @application.component_instances.find_by(cartridge_name: cart.name, component_name: comp.name)
      cartridge = get_rest_cartridge(@application, component_instance, @application.group_instances_with_scale, @application.group_overrides)

      messages = []
      log_msg = "Added #{name} to application #{@application.name}"
      messages.push(Message.new(:info, log_msg))
      messages.push(Message.new(:info, cart_create_reply.resultIO.string, 0, :result))
      messages.push(Message.new(:info, cart_create_reply.appInfoIO.string, 0, :appinfo))
      return render_success(:created, "cartridge", cartridge, log_msg, nil, nil, messages)
    rescue OpenShift::GearLimitReachedException => e
      return render_error(:unprocessable_entity, "Unable to add cartridge: #{e.message}", 104)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, "Invalid cartridge. #{e.message}", 109, "cartridge")
    end
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def destroy
    cartridge = params[:id]

    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if cartridge !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{@application.name}", 129)
    end

    begin
      comp = @application.component_instances.find_by(cartridge_name: cartridge)
      feature = @application.get_feature(comp.cartridge_name, comp.component_name)  
      return render_error(:not_found, "Cartridge '#{cartridge}' not found for application '#{@application.name}'", 101, "REMOVE_CARTRIDGE") if feature.nil?   
      @application.remove_features([feature])

      render_success(:no_content, nil, nil, "Removed #{cartridge} from application #{@application.name}", true)
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{@application.name}", 129)
    end
  end

  # PUT /domains/[domain_id]/applications/[application_id]/cartridges/[id]
  def update
    id = params[:id]
    scales_from = Integer(params[:scales_from]) rescue nil
    scales_to = Integer(params[:scales_to]) rescue nil
    additional_storage = params[:additional_gear_storage]

    if scales_from.nil? and scales_to.nil? and additional_storage.nil?
      return render_error(:unprocessable_entity, "No update parameters specified.  Valid update parameters are: scales_from, scales_to, additional_gear_storage", 168) 
    end

    begin
      additional_storage = Integer(additional_storage) if additional_storage
    rescue
      return render_error(:unprocessable_entity, "Invalid storage value provided.", 165, "additional_storage")
    end
    
    # validate the cartridge name using regex to avoid a mongo call, if it is malformed
    if id !~ CART_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Cartridge #{id} not embedded within application #{@application.name}", 129)
    end

    begin
      if !@application.scalable and ((scales_from and scales_from != 1) or (scales_to and scales_to != 1 and scales_to != -1))
        return render_error(:unprocessable_entity, "Application '#{@application.name}' is not scalable", 100, "name")
      end

      if scales_from and scales_from < 1
        return render_error(:unprocessable_entity, "Invalid scales_from factor #{scales_from} provided", 168, "scales_from") 
      end

      if scales_to and (scales_to == 0 or scales_to < -1)
        return render_error(:unprocessable_entity, "Invalid scales_to factor #{scales_to} provided", 168, "scales_to") 
      end

      if scales_to and scales_from and scales_to >= 1 and scales_to < scales_from
        return render_error(:unprocessable_entity, "Invalid scales_(from|to) factor provided", 168, "scales_to") 
      end

      begin
        component_instance = @application.component_instances.find_by(cartridge_name: id)
      rescue Mongoid::Errors::DocumentNotFound
        return render_error(:not_found, "Cartridge #{id} not embedded within application #{@application.name}", 129)
      end

      if component_instance.nil?
        return render_error(:unprocessable_entity, "Invalid cartridge #{id} for application #{@application.name}", 168, "PATCH_APP_CARTRIDGE", "cartridge")
      end

      if component_instance.is_singleton?
        if scales_to and scales_to != 1
          return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_to")
        elsif scales_from and scales_from != 1
          return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_from")
        end
      end
      
      group_instance = @application.group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]

      if scales_to and scales_from.nil? and scales_to >= 1 and scales_to < group_instance.min
        return render_error(:unprocessable_entity, "The scales_to factor currently provided cannot be lower than the scales_from factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "scales_to") 
      end

      if scales_from and scales_to.nil? and group_instance.max >= 1 and group_instance.max < scales_from
        return render_error(:unprocessable_entity, "The scales_from factor currently provided cannot be higher than the scales_to factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "scales_from") 
      end

      @application.update_component_limits(component_instance, scales_from, scales_to, additional_storage)

      component_instance = @application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(@application, component_instance, @application.group_instances_with_scale, @application.group_overrides)
      return render_success(:ok, "cartridge", cartridge, "Showing cartridge #{id} for application #{@application.name} under domain #{@domain.namespace}")
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "cartridge '#{id}' not found for application '#{@application.name}'", 101)
    rescue Exception => e
      return render_exception(e)
    end

    return render_success(:ok, "cartridge", [], "")  
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "APP_CARTRIDGE"
  end
end
