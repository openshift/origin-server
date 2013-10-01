class UpdateAppConfigOp < PendingAppOp

  field :add_keys_attrs, type: Array, default: []
  field :remove_keys_attrs, type: Array, default: []
  field :add_env_vars, type: Array, default: []
  field :remove_env_vars, type: Array, default: []

  field :group_instance_id, type: String
  field :gear_id, type: String

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.node_removed
      tag = { "op_id" => self._id.to_s }
      gear.update_configuration(self, handle, tag)
    end
  end

end
