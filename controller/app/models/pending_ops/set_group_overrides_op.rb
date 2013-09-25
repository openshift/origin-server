class SetGroupOverridesOp < PendingAppOp

  field :group_overrides, type: Array, default: []
  field :saved_group_overrides, type: Array, default: []
  
  def execute(skip_node_ops=false)
    pending_app_op_group.application.group_overrides = group_overrides
    pending_app_op_group.application.save
  end

  def rollback(skip_node_ops=false)
    pending_app_op_group.application.group_overrides = saved_group_overrides
    pending_app_op_group.application.save
  end

end
