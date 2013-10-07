class RestartAppOpGroup < PendingAppOpGroup

  def elaborate(app)
    ops = []
    start_order, stop_order = app.calculate_component_orders
    start_order.each do |component_instance|
      component_instance.group_instance.get_gears(component_instance).each do |gear|
        if app.scalable? && component_instance.is_web_framework?
          if gear.app_dns
            ops.push(RollingRestartCompOp.new(group_instance_id: component_instance.group_instance._id.to_s, gear_id: gear._id.to_s, comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
          end
        else
          ops.push(RestartCompOp.new(group_instance_id: component_instance.group_instance._id.to_s, gear_id: gear._id.to_s, comp_spec: {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}))
        end
      end
    end
    pending_ops.push(*ops)
  end

end
