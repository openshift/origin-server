class UpdateCompIds < PendingAppOp
  field :comp_specs, type: TypedArray[ComponentSpec]
  field :saved_comp_specs, type: TypedArray[ComponentSpec]

  def execute
    if comp_specs.present?
      comp_specs.each do |spec|
        if instance = application.find_component_instance_for(spec)
          instance.cartridge_id = spec.id
        end
      end
      application.save!
    end
  end

  def rollback
    if saved_comp_specs.present?
      saved_comp_specs.each do |spec|
        if instance = application.find_component_instance_for(spec)
          instance.cartridge_id = spec.id
        end
      end
      application.save!
    end
  rescue
    if_not_found($!)
  end

  def reexecute_connections?
    return false
  end

end