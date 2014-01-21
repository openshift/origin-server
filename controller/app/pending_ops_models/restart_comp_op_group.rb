class RestartCompOpGroup < PendingAppOpGroup

  field :comp_spec, type: ComponentSpec, default: {}

  def elaborate(app)
    ops = []
    component_instance = get_component_instance
    component_instance.gears.each do |gear|
      if app.scalable? && component_instance.is_web_framework?
        if gear.app_dns
          ops.push(RollingRestartCompOp.new(gear_id: gear._id.to_s, comp_spec: component_instance.to_component_spec))
        end
      else
        ops.push(RestartCompOp.new(gear_id: gear._id.to_s, comp_spec: component_instance.to_component_spec))
      end
    end
    pending_ops.push(*ops)
  end

end
