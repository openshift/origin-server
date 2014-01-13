class NewCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :comp_spec, type: ComponentSpec, default: {}
  field :cartridge_vendor, type: String
  field :version, type: String

  def execute
    group_instance = get_group_instance()
    if comp_spec
      comp_spec.application = application
      comp_name = comp_spec.name
      cartridge = comp_spec.cartridge
      component_instance = ComponentInstance.new(cartridge_name: comp_spec.cartridge_name,
                                                 cartridge_id: cartridge.id,
                                                 component_name: comp_name,
                                                 group_instance_id: group_instance._id,
                                                 cartridge_vendor: cartridge.cartridge_vendor,
                                                 version: cartridge.version)
      application.component_instances.push(component_instance)
    end
  end
  
  def rollback
    begin
      component_instance = get_component_instance()
      application.component_instances.delete(component_instance)
      # If this was a downloaded cart, remove it from the downloaded cart map
      application.downloaded_cart_map.delete_if { |cname, c| c["versioned_name"] == comp_spec["cart"] }
      application.save!
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if component instance is already deleted
    end
  end

end
