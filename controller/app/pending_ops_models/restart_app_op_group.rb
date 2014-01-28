class RestartAppOpGroup < PendingAppOpGroup

  def elaborate(app)
    ops = []
    start_order, _ = app.calculate_component_orders
    start_order.each do |instance|
      instance.gears.each do |gear|
        if app.scalable? && instance.is_web_framework?
          if gear.app_dns
            ops << RollingRestartCompOp.new(gear_id: gear._id.to_s, comp_spec: instance.to_component_spec)
          end
        else
          ops << RestartCompOp.new(gear_id: gear._id.to_s, comp_spec: instance.to_component_spec)
        end
      end
    end
    pending_ops.concat(ops)
  end

end
