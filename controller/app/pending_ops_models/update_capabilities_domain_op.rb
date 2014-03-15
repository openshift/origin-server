class UpdateCapabilitiesDomainOp < PendingDomainOps

  field :old_capabilities, type: Hash
  field :new_capabilities, type: Hash

  def execute
    if (old_capabilities['gear_sizes'].sort == domain.allowed_gear_sizes.sort) and
       (old_capabilities['gear_sizes'].sort != new_capabilities['gear_sizes'].sort)
      domain.allowed_gear_sizes = new_capabilities['gear_sizes']
    else
      domain.allowed_gear_sizes = (domain.allowed_gear_sizes & new_capabilities['gear_sizes'])
    end
    domain.save!
  end

end
