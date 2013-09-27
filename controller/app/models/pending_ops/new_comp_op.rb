class NewCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :comp_spec, type: Hash, default: {}
  field :cartridge_vendor, type: String
  field :version, type: String

  def execute
    group_instance = get_group_instance()
    if comp_spec
      comp_name = comp_spec["comp"]
      cart_name = comp_spec["cart"]
      component_instance = ComponentInstance.new(cartridge_name: cart_name, component_name: comp_name, group_instance_id: group_instance._id, cartridge_vendor: cartridge_vendor, version: version)
      pending_app_op_group.application.component_instances.push(component_instance)
    end
  end
  
  def rollback
    begin
      component_instance = get_component_instance()
      pending_app_op_group.application.component_instances.delete(component_instance)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if component instance is already deleted
    end
  end

end
