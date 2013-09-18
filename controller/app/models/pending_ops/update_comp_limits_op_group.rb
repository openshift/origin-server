class UpdateCompLimitsOpGroup < PendingAppOpGroup

  field :comp_spec, type: Hash, default: {}
  field :min, type: Integer
  field :max, type: Integer
  field :multiplier, type: Integer
  field :additional_filesystem_gb, type: Integer

  def elaborate(app)
    updated_overrides = (app.group_overrides || []).deep_dup
    ci = app.component_instances.find_by(cartridge_name: comp_spec["cart"], component_name: comp_spec["comp"])
    found = updated_overrides.find {|go|
      go["components"].find { |go_comp_spec| ci.cartridge_name==go_comp_spec["cart"] and ci.component_name==go_comp_spec["comp"] }
    }
    if ci.is_sparse?
      if found
        updated_overrides.each { |go|
          go["components"].each { |go_comp_spec|
            if go_comp_spec["cart"] == ci.cartridge_name and go_comp_spec["comp"] == ci.component_name
              go_comp_spec["min_gears"] = min unless min.nil?
              go_comp_spec["max_gears"] = max unless max.nil?
              go_comp_spec["multiplier"] = multiplier unless multiplier.nil?
            end
          }
        }
        group_override = found
      else
        new_comp_spec = { "cart"=> ci.cartridge_name, "comp" => ci.component_name }
        new_comp_spec["min_gears"] = min unless min.nil?
        new_comp_spec["max_gears"] = max unless max.nil?
        new_comp_spec["multiplier"] = multiplier unless multiplier.nil?
        group_override = {"components" => [new_comp_spec]}
      end
    else
      group_override = found || {"components" => [comp_spec]}
      group_override["min_gears"] = min unless min.nil?
      group_override["max_gears"] = max unless max.nil?
    end
    group_override["additional_filesystem_gb"] = additional_filesystem_gb unless additional_filesystem_gb.nil?
    updated_overrides.push(group_override) unless found
    features = app.requires
    ops, add_gear_count, rm_gear_count = app.update_requirements(features, updated_overrides)
    try_reserve_gears(add_gear_count, rm_gear_count, app, ops)
  end

end
