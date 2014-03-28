class StopAppOpGroup < PendingAppOpGroup

  field :force, type: Boolean, default: false

  def elaborate(app)
    ops = []
    start_order, stop_order = app.calculate_component_orders
    stop_order.each do |component_instance|
      component_instance.gears.each do |gear|
        ops.push(StopCompOp.new(gear_id: gear._id.to_s, force: force,
                                comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
      end
    end
    pending_ops.push(*ops)
  end

end
