class AddCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :gear_id, type: String
  field :comp_spec, type: Hash, default: {}
  field :init_git_url, type: String

  def execute(skip_node_ops=false)
    gear = get_gear()
    component_instance = get_component_instance()
    result_io = gear.add_component(component_instance, init_git_url, skip_node_ops)
    gear.save! if component_instance.is_sparse?
    result_io
  end
  
  def rollback(skip_node_ops=false)
    gear = get_gear()
    component_instance = get_component_instance_for_rollback(op)
    result_io = gear.remove_component(component_instance, skip_node_ops)
    result_io
  end

end
