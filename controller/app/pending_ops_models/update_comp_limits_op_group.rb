class UpdateCompLimitsOpGroup < PendingAppOpGroup

  field :comp_spec, type: ComponentSpec, default: {}
  field :min, type: Integer
  field :max, type: Integer
  field :multiplier, type: Integer
  field :additional_filesystem_gb, type: Integer

  def elaborate(app)
    overrides = app.application_overrides
    instance = app.find_component_instance_for(comp_spec)

    found = false
    if instance.is_sparse?
      instance.group_overrides do |override|
        if component = override.components.find{ |c| c == comp_spec }
          found = true
          component.merge(min, max, multiplier)
          override.merge(GroupOverride.new(nil, nil, nil, nil, additional_filesystem_gb))
        end
      end
      unless found
        overrides << GroupOverride.new([ComponentOverrideSpec.new(comp_spec, min, max, multiplier)], nil, nil, nil, additional_filesystem_gb)
      end
    else
      instance.group_overrides do |override|
        found = true
        override.merge(GroupOverride.new(nil, min, max, nil, additional_filesystem_gb))
      end
      unless found
        overrides << GroupOverride.new([comp_spec], min, max, nil, additional_filesystem_gb)
      end
    end

    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges, overrides)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

end
