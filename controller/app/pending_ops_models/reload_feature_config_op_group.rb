class ReloadFeatureConfigOpGroup < PendingAppOpGroup

  field :feature, type: String

  def elaborate(app)
    ops = []
    component_instances = app.get_components_for_feature(feature)
    start_order, stop_order = app.calculate_component_orders
    start_order.each do |component_instance|
      if component_instances.include? component_instance
        component_instance.gears.each do |gear|
          ops.push(ReloadCompConfigOp.new(gear_id: gear._id.to_s, comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
        end
      end
    end
    pending_ops.push(*ops)
  end

end
