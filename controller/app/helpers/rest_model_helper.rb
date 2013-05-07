module RestModelHelper
  def get_rest_application(application, include_cartridges=false, applications=nil)
    if requested_api_version == 1.0
        app = RestApplication10.new(application, @domain, get_url, nolinks, applications)
    elsif requested_api_version <= 1.3
        app = RestApplication13.new(application, @domain, get_url, nolinks, applications)
    else
        app = RestApplication.new(application, @domain, get_url, nolinks, applications)
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
          cartridges << get_rest_cartridge(application, component_instance, group_instances, application.group_overrides) if component_instance.is_embeddable?
        else
          cartridges << get_rest_cartridge(application, component_instance, group_instances, application.group_overrides)
        end
      end
    end
    cartridges
  end

  def get_rest_cartridge(application, component_instance, group_instances_with_scale, group_overrides, include_status_messages=false)
    group_instance = group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    group_component_instances = group_instance.all_component_instances
    colocated_instances = group_component_instances - [component_instance]
    messages = application.component_status(component_instance) if include_status_messages

    additional_storage = 0
    group_override = group_overrides.nil? ? nil : group_overrides.select{ |go| go["components"].include? component_instance.to_hash }.first 
    additional_storage = group_override["additional_filesystem_gb"] if !group_override.nil? and group_override.has_key?("additional_filesystem_gb")

    scale = {min: group_instance.min, max: group_instance.max, gear_size: group_instance.gear_size, additional_storage: additional_storage, current: group_instance.gears.count}

    cart = CartridgeCache.find_cartridge(component_instance.cartridge_name, application)
    comp = cart.get_component(component_instance.component_name)
    if requested_api_version == 1.0
      RestEmbeddedCartridge10.new(cart, application, @domain, component_instance, get_url, messages, nolinks)
    else
      RestEmbeddedCartridge.new(cart, comp, application, @domain, component_instance, colocated_instances, scale, get_url, messages, nolinks)
    end
  end
  
  def get_rest_alias(al1as)
     RestAlias.new(@application, @domain, al1as, get_url, nolinks)
  end
end
