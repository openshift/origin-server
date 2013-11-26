class StartAppOpGroup < PendingAppOpGroup

  def elaborate(app)
    ops = []
    start_order, stop_order = app.calculate_component_orders
    start_order.each do |component_instance|
      component_instance.gears.each do |gear|
        ops.push(StartCompOp.new(gear_id: gear._id.to_s, comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
      end
    end
    pending_ops.push(*ops)
  end

end
