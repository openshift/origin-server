module RestModelHelper
  def get_rest_user(cloud_user)
    if requested_api_version == 1.0
      user = RestUser10.new(cloud_user, get_url, nolinks)
    else
      user = RestUser.new(cloud_user, get_url, nolinks)
    end
    user
  end

  # Creates a new [RestDomain] or [RestDomain10] based on the requested API version.
  #
  # @param [Domain] domain The Domain object
  # @param [CloudUser] owner of the Domain
  # @return [RestDomain] REST object for API version > 1.0
  # @return [RestDomain10] REST object for API version == 1.0
  def get_rest_domain(domain)
    if requested_api_version == 1.0
      RestDomain10.new(domain, get_url, nolinks)
    elsif requested_api_version <= 1.2
      RestDomain12.new(domain, get_url, nolinks)
    elsif requested_api_version <= 1.5
      RestDomain15.new(domain, get_url, nolinks)
    else
      RestDomain.new(domain, get_url, nolinks)
    end
  end

  def get_rest_application(application, include_cartridges=false, applications=nil)
    if requested_api_version == 1.0
      app = RestApplication10.new(application, get_url, nolinks, applications)
    elsif requested_api_version <= 1.3
      app = RestApplication13.new(application, get_url, nolinks, applications)
    elsif requested_api_version <= 1.5
      app = RestApplication15.new(application, get_url, nolinks, applications)
    else
      app = RestApplication.new(application, get_url, nolinks, applications)
    end
    if include_cartridges
      app.cartridges = get_application_rest_cartridges(application)
    end
    app
  end

  def get_application_rest_cartridges(application)
    group_instances = application.group_instances_with_scale

    cartridges = []
    group_instances.each do |group_instance|
      component_instances = group_instance.all_component_instances
      component_instances.each do |component_instance|
        if requested_api_version == 1.0
          cartridges << get_embedded_rest_cartridge(application, component_instance, group_instances, application.group_overrides) if component_instance.is_embeddable?
        else
          cartridges << get_embedded_rest_cartridge(application, component_instance, group_instances, application.group_overrides)
        end
      end
    end
    cartridges
  end

  def get_embedded_rest_cartridge(application, component_instance, group_instances_with_scale, group_overrides, include_status_messages=false)
    group_instance = group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    group_component_instances = group_instance.all_component_instances
    colocated_instances = group_component_instances - [component_instance]
    messages = application.component_status(component_instance) if include_status_messages

    additional_storage = 0
    group_override = group_overrides.nil? ? nil : group_overrides.select{ |go| go["components"].any?{ |c| c['cart'] == component_instance.cartridge_name && c['comp'] == component_instance.component_name } }.first
    additional_storage = group_override["additional_filesystem_gb"] if !group_override.nil? and group_override.has_key?("additional_filesystem_gb")

    scale = {min: group_instance.min, max: group_instance.max, gear_size: group_instance.gear_size, additional_storage: additional_storage, current: group_instance.gears.count}

    cart = CartridgeCache.find_cartridge(component_instance.cartridge_name, application)

    # raise an exception in case the application cartridge is not found
    raise OpenShift::OOException.new("The application '#{application.name}' requires '#{component_instance.cartridge_name}' but a matching cartridge could not be found") if cart.nil?

    comp = cart.get_component(component_instance.component_name)
    if requested_api_version == 1.0
      RestEmbeddedCartridge10.new(cart, application, component_instance, get_url, messages, nolinks)
    elsif requested_api_version <= 1.5
      RestEmbeddedCartridge15.new(cart, comp, application, component_instance, colocated_instances, scale, get_url, messages, nolinks)
    else
      RestEmbeddedCartridge.new(cart, comp, application, component_instance, colocated_instances, scale, get_url, messages, nolinks)
    end
  end
 
  def get_rest_cartridge(cartridge)
    if requested_api_version == 1.0
      RestCartridge10.new(cartridge)
    else
      RestCartridge.new(cartridge)
    end
  end
 
  def get_rest_alias(al1as)
    if requested_api_version <= 1.5
      RestAlias15.new(@application, al1as, get_url, nolinks)
    else
      RestAlias.new(@application, al1as, get_url, nolinks)
    end
  end
 
  def get_rest_environment_variable(env_var)
    if requested_api_version <= 1.5
      RestEnvironmentVariable15.new(@application, env_var, get_url, nolinks)
    else
      RestEnvironmentVariable.new(@application, env_var, get_url, nolinks)
    end
  end
 
  def get_rest_gear_group(group_inst, gear_states, application, get_url, nolinks, include_endpoints)
    if requested_api_version <= 1.5
      RestGearGroup15.new(group_inst, gear_states, application, get_url, nolinks)
    else
      RestGearGroup.new(group_inst, gear_states, application, get_url, nolinks, include_endpoints) 
    end
  end
  
  def get_rest_deployment(deployment)
    RestDeployment.new(deployment)
  end
end
