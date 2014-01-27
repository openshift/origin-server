class StopFeatureOpGroup < PendingAppOpGroup

  field :feature, type: String

  def elaborate(app)
    ops = []
    _, stop_order = app.calculate_component_orders
    stop_order.each do |instance|
      next if instance.cartridge_name == feature
      instance.gears.each do |gear|
        ops << StopCompOp.new(gear_id: gear._id.to_s, comp_spec: instance.to_component_spec)
      end
    end
    pending_ops.push(*ops)
  end
end
