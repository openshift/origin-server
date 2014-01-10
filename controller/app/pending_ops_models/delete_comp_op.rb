class DeleteCompOp < PendingAppOp

  field :comp_spec, type: Hash, default: {}

  def execute
    component_instance = get_component_instance()
    application.downloaded_cart_map.delete_if { |cname, c| c["versioned_name"] == component_instance.cartridge_name}
    application.component_instances.delete(component_instance)
    application.save!
  end

end
