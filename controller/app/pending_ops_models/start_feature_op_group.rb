class StartFeatureOpGroup < PendingAppOpGroup

  field :feature, type: String

  def elaborate(app)
    ops = []
    start_order, _ = app.calculate_component_orders
    start_order.each do |instance|
      next if instance.cartridge_name != feature
      instance.gears.each do |gear|
        ops << StartCompOp.new(gear_id: gear._id.to_s, comp_spec: instance.to_component_spec)
      end
    end
    pending_ops.push(*ops)
  end

end
