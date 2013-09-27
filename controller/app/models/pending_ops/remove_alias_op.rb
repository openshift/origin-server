class RemoveAliasOp < PendingAppOp

  field :fqdn, type: String
  field :group_instance_id, type: String
  field :gear_id, type: String

  def execute(skip_node_ops=false)
    result_io = ResultIO.new
    unless skip_node_ops
      gear = get_gear()
      result_io = gear.remove_alias(fqdn)
    end
    a = pending_app_op_group.application.aliases.find_by(fqdn: fqdn)
    pending_app_op_group.application.aliases.delete(a)
    pending_app_op_group.application.save
    result_io
  end

  def rollback(skip_node_ops=false)
    result_io = ResultIO.new
    unless skip_node_ops
      gear = get_gear()
      result_io = gear.add_alias(fqdn)
    end  
    a = pending_app_op_group.application.aliases.find_by(fqdn: fqdn) rescue nil
    unless a
      pending_app_op_group.application.aliases.push(Alias.new(fqdn: fqdn))
      pending_app_op_group.application.save
    end
    result_io
  end

end
