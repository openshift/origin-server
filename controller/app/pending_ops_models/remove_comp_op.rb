class RemoveCompOp < PendingAppOp

  field :gear_id, type: String
  field :comp_spec, type: ComponentSpec, default: {}

  def execute
    gear = get_gear
    component_instance = get_component_instance
    result_io = gear.remove_component(component_instance)
    result_io
  end

end
