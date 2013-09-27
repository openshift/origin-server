class RemoveCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :gear_id, type: String
  field :comp_spec, type: Hash, default: {}

  def execute(skip_node_ops=false)
    gear = get_gear()
    component_instance = get_component_instance()
    result_io = gear.remove_component(component_instance, skip_node_ops)
    gear.save! if component_instance.is_sparse?
    result_io
  end

end
