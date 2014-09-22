class SetGroupOverridesOp < PendingAppOp

  field :group_overrides, type: TypedArray[GroupOverride], default: []
  field :saved_group_overrides, type: TypedArray[GroupOverride], default: []
  field :pre_save, type: Boolean, default: false

  def execute
    application.set :group_overrides, group_overrides.mongoize
  end

  def rollback
    application.set :group_overrides, saved_group_overrides.mongoize
  end

  def reexecute_connections?
    return false
  end

end
