class ResendAliasesOp < PendingAppOp

  field :gear_id, type: String
  field :fqdns, type: Array

  def execute
    result_io = ResultIO.new 
    gear = get_gear()
    result_io = gear.add_aliases(fqdns) unless gear.removed
    result_io
  end

  def rollback
    result_io = nil
    unless skip_rollback
      gear = get_gear()
      result_io = gear.remove_aliases(fqdns) unless gear.removed
    end
    result_io
  end

end
