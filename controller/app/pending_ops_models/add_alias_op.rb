class AddAliasOp < PendingAppOp

  field :fqdn, type: String
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new 
    gear = get_gear()
    result_io = gear.add_alias(fqdn) unless gear.removed
    application.aliases.push(Alias.new(fqdn: fqdn))
    application.save!
    result_io
  end

  def rollback
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.remove_alias(fqdn) unless gear.removed
    begin
      a = application.aliases.find_by(fqdn: fqdn)
      application.aliases.delete(a)
      application.save!
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if alias is not found
    end

    result_io
  end

end
