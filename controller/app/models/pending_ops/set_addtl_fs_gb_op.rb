class SetAddtlFsGbOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String
  field :addtl_fs_gb, type: Integer
  field :saved_addtl_fs_gb, type: Integer

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.removed
      tag = { "op_id" => self._id.to_s }
      gear.set_addtl_fs_gb(addtl_fs_gb, handle, tag)
    end
  end

  def addParallelRollbackJob(handle)
    gear = get_gear()
    unless gear.removed
      tag = { "op_id" => self._id.to_s }
      gear.set_addtl_fs_gb(saved_addtl_fs_gb, handle, tag)
    end
  end

end
