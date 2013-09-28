class DeleteCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :comp_spec, type: Hash, default: {}

  def execute
    component_instance = get_component_instance()
    cartname = component_instance.cartridge_name
    pending_app_op_group.application.component_instances.delete(component_instance)
    pending_app_op_group.application.downloaded_cart_map.delete_if { |cname, c| c["versioned_name"] == component_instance.cartridge_name}
    pending_app_op_group.application.save
  end

end
