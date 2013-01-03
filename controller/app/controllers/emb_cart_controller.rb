class EmbCartController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include RestModelHelper

  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_CARTRIDGES")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      @application_name = application.name
      @application_uuid = application._id.to_s
      cartridges = get_application_rest_cartridges(application) if application
      
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
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: application_id)
      @application_name = application.name
      @application_uuid = application._id.to_s
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_CARTRIDGE")
    end
    
    begin
      component_instance = application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(application, component_instance, application.group_instances_with_scale, application.group_overrides, status_messages)
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

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "EMBED_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      @application_name = application.name
      @application_uuid = application._id.to_s
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
        return render_error(:bad_request, "Invalid colocation specified. No component matches #{colocate_with}", 109, "EMBED_CARTRIDGE", "cartridge")      
      end
    end
    
    begin
      group_overrides = []
      # Todo: REST API assumes cartridge only has one component
      cart = CartridgeCache.find_cartridge(name)
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
      
      application.add_features([name], group_overrides)
      
      
      component_instance = application.component_instances.find_by(cartridge_name: cart.name, component_name: comp.name)
      cartridge = get_rest_cartridge(application, component_instance, application.group_instances_with_scale, application.group_overrides)
      return render_success(:created, "cartridge", cartridge, "EMBED_CARTRIDGE", nil, nil, nil, nil)
    rescue OpenShift::UserException => e
      return render_error(:bad_request, "Invalid cartridge. #{e.message}", 109, "EMBED_CARTRIDGE", "cartridge")
    end
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:id]

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "REMOVE_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      @application_name = application.name
      @application_uuid = application._id.to_s
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "REMOVE_CARTRIDGE")
    end
    
    begin
      comp = application.component_instances.find_by(cartridge_name: cartridge)
      feature = application.get_feature(comp.cartridge_name, comp.component_name)
      if CartridgeCache.find_cartridge(cartridge).categories.include?("web_framework")
        raise OpenShift::UserException.new("Invalid cartridge #{id}")
      end
      
      application.remove_features([feature])
      
      if $requested_api_version == 1.0
        app = RestApplication10.new(application, get_url, nolinks)
      else
        app = RestApplication.new(application, get_url, nolinks)
      end
      
      render_success(:ok, "application", app, "REMOVE_CARTRIDGE", "Removed #{cartridge} from application #{id}", true)
    rescue OpenShift::UserException => e
      return render_error(:bad_request, "Application is currently busy performing another operation. Please try again in a minute.", 129, "REMOVE_CARTRIDGE")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:bad_request, "Cartridge #{cartridge} not embedded within application #{id}", 129, "REMOVE_CARTRIDGE")
    end
  end

  def update
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    scales_from = Integer(params[:scales_from]) rescue nil
    scales_to = Integer(params[:scales_to]) rescue nil
    additional_storage = Integer(params[:additional_gear_storage]) rescue nil
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "PATCH_APP_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: application_id)
      @application_name = application.name
      @application_uuid = application._id.to_s
 
      if !application.scalable and (scales_from != 1 or scales_to != 1)
        return render_error(:unprocessable_entity, "Application '#{application_id}' is not scalable", 100, "PATCH_APP_CARTRIDGE", "name")
      end
      
      if scales_from < 1
        return render_error(:unprocessable_entity, "Invalid scales_(from|to) factor #{scales_from} provided", 168, "PATCH_APP_CARTRIDGE", "scales_from")
      end
      
      if scales_to < -1
        return render_error(:unprocessable_entity, "Invalid scales_(from|to) factor #{scales_to} provided", 168, "PATCH_APP_CARTRIDGE", "scales_to")
      end
      component_instance = application.component_instances.find_by(cartridge_name: id)

      application.update_component_limits(component_instance, scales_from, scales_to, additional_storage)

      component_instance = application.component_instances.find_by(cartridge_name: id)
      cartridge = get_rest_cartridge(application, component_instance, application.group_instances_with_scale, application.group_overrides)
      return render_success(:ok, "cartridge", cartridge, "SHOW_APP_CARTRIDGE", "Showing cartridge #{id} for application #{application_id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "PATCH_APP_CARTRIDGE")
    end
    
    return render_success(:ok, "cartridge", [], "PATCH_APP_CARTRIDGE", "")  
  end
end
