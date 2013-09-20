class ReloadCompConfigOpGroup < PendingAppOpGroup

  field :comp_spec, type: Hash, default: {}

  def elaborate(app)
    ops = []
    component_instance = app.component_instances.find_by(cartridge_name: comp_spec['cart'], component_name: comp_spec['comp'])
    component_instance.group_instance.get_gears(component_instance).each do |gear|
      ops.push(ReloadCompConfigOp.new(group_instance_id: component_instance.group_instance._id.to_s, gear_id: gear._id.to_s, comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
    end
    pending_ops.push(*ops)
  end

end
