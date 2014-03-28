class StopFeatureOpGroup < PendingAppOpGroup

  field :feature, type: String

  def elaborate(app)
    ops = []
    if instance = app.component_instances.detect{ |c| c.cartridge_name == feature }
      instance.gears.each do |gear|
        ops << StopCompOp.new(gear_id: gear._id.to_s, comp_spec: instance.to_component_spec)
      end
    end
    pending_ops.concat(ops)
  end
end