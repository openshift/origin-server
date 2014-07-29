class UpdateCompLimitsOpGroup < PendingAppOpGroup

  field :comp_spec, type: ComponentSpec, default: {}
  field :min, type: Integer
  field :max, type: Integer
  field :multiplier, type: Integer
  field :additional_filesystem_gb, type: Integer

  def elaborate(app)
    spec = comp_spec
    overrides = app.group_overrides.compact
    instance = app.find_component_instance_for(spec)

    found = false
    if instance.is_sparse?
      overrides.each do |override|
        if component = override.components.find{ |c| c == spec }
          found = true
          if ComponentOverrideSpec === component
            component.reset(min || component.min_gears, max || component.max_gears, multiplier || component.multiplier)
            override.reset(override.min_gears, override.max_gears, override.gear_size, additional_filesystem_gb || override.additional_filesystem_gb)
          # if multiplier is specified, we need to include it in the overrides
          elsif multiplier
            found = false
          else
            override.reset(min || override.min_gears, max || override.max_gears, override.gear_size, additional_filesystem_gb || override.additional_filesystem_gb)
          end
        end
      end
      unless found
        overrides << GroupOverride.new([ComponentOverrideSpec.new(spec, min, max, multiplier)], nil, nil, nil, additional_filesystem_gb)
        overrides = GroupOverride.reduce(overrides)
      end
    else
      overrides.each do |override|
        if override.components.any?{ |c| c == spec }
          found = true
          override.reset(min || override.min_gears, max || override.max_gears, override.gear_size, additional_filesystem_gb || override.additional_filesystem_gb)
        end
      end
      unless found
        overrides << GroupOverride.new([spec], min, max, nil, additional_filesystem_gb)
      end
    end

    ops, add_gear_count, rm_gear_count = app.update_requirements(app.cartridges, nil, overrides)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

end
