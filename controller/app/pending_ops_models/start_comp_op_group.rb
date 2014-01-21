class StartCompOpGroup < PendingAppOpGroup

  field :comp_spec, type: ComponentSpec, default: {}

  def elaborate(app)
    ops = []
    component_instance = get_component_instance
    component_instance.gears.each do |gear|
      ops.push(StartCompOp.new(gear_id: gear._id.to_s, comp_spec: component_instance.to_component_spec))
    end
    pending_ops.push(*ops)
  end
end
