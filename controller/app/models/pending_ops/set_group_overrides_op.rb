class SetGroupOverridesOp < PendingAppOp

  field :group_overrides, type: Array, default: []
  field :saved_group_overrides, type: Array, default: []
  
  def execute
    pending_app_op_group.application.set :group_overrides, group_overrides
  end

  def rollback
    pending_app_op_group.application.set :group_overrides, saved_group_overrides
  end

end
