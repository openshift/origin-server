class RemoveAliasOp < PendingAppOp

  field :fqdn, type: String
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.remove_alias(fqdn) unless gear.removed
    a = application.aliases.find_by(fqdn: fqdn)
    application.aliases.delete(a)
    application.save!
    result_io
  end

  def rollback
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.add_alias(fqdn) unless gear.removed
    a = application.aliases.find_by(fqdn: fqdn) rescue nil
    unless a
      application.aliases.push(Alias.new(fqdn: fqdn))
      application.save!
    end
    result_io
  end

end
