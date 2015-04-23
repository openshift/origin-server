class RemoveAliasOp < PendingAppOp

  field :fqdn, type: String
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.remove_alias(fqdn) unless gear.removed

    begin
      a = application.aliases.find_by(fqdn: fqdn)
      application.aliases.delete(a)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if alias is not found
    end

    OpenShift::SsoService.deregister_alias(gear,fqdn) unless gear.removed

    result_io
  end

  def rollback
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.add_alias(fqdn) unless gear.removed

    begin
      application.aliases.find_by(fqdn: fqdn)
    rescue Mongoid::Errors::DocumentNotFound
      # add the alias only if it is not present already
      application.aliases.push(Alias.new(fqdn: fqdn))
      application.save!
    end

    OpenShift::SsoService.register_gear(gear) unless gear.removed

    result_io
  end

end
