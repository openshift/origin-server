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
    application.group_instances_with_overrides.inject([]) do |cartridges, group|
      instances = group.instance.all_component_instances
      instances.each do |component|
        if requested_api_version == 1.0
          cartridges << get_embedded_rest_cartridge(application, component, instances, group) if component.is_embeddable?
        else
          cartridges << get_embedded_rest_cartridge(application, component, instances, group)
        end
      end
      cartridges
    end
  end

  def get_embedded_rest_cartridge(application, component, others, group, include_status_messages=false)
    colocated = others - [component]
    messages = application.component_status(component) if include_status_messages
    scale = {min: group.min_gears, max: group.max_gears, gear_size: group.gear_size, additional_storage: group.additional_filesystem_gb, current: group.instance.gears.count}
    cart = component.cartridge
    comp = component.component

    if requested_api_version == 1.0
      RestEmbeddedCartridge10.new(cart, application, component, get_url, messages, nolinks)
    elsif requested_api_version <= 1.5
      requires = CartridgeCache.find_requires_for(cart)
      RestEmbeddedCartridge15.new(cart, comp, application, component, colocated, scale, get_url, requires, messages, nolinks)
    else
      requires = CartridgeCache.find_requires_for(cart)
      RestEmbeddedCartridge.new(cart, comp, application, component, colocated, scale, get_url, requires, messages, nolinks)
    end
  end

  def get_rest_cartridge(cartridge)
    if requested_api_version == 1.0
      RestCartridge10.new(cartridge)
    else 
      requires = CartridgeCache.find_requires_for(cartridge)
      return RestCartridge16.new(cartridge) if requested_api_version <= 1.6
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

  def get_rest_gear_group(group_inst, gear_states, application, get_url, nolinks, include_endpoints, servers)
    if requested_api_version <= 1.5
      RestGearGroup15.new(group_inst, gear_states, application, get_url, nolinks)
    else
      RestGearGroup.new(group_inst, gear_states, application, get_url, nolinks, include_endpoints, servers)
    end
  end

  def get_rest_deployment(deployment)
    RestDeployment.new(deployment)
  end
  
  def get_rest_team(team, include_members)
    RestTeam.new(team, get_url, nolinks, include_members)
  end
end
