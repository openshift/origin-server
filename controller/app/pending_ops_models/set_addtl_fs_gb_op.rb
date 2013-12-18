class SetAddtlFsGbOp < PendingAppOp

  field :gear_id, type: String
  field :addtl_fs_gb, type: Integer
  field :saved_addtl_fs_gb, type: Integer

  def is_parallel_executable
    return true
  end

  def add_parallel_execute_job(handle)
    gear = get_gear()
    unless gear.removed
      tag = { "op_id" => self._id.to_s }
      gear.set_addtl_fs_gb(addtl_fs_gb, handle, tag)
    end
  end

  def add_parallel_rollback_job(handle)
    gear = get_gear()
    unless gear.removed
      tag = { "op_id" => self._id.to_s }
      gear.set_addtl_fs_gb(saved_addtl_fs_gb, handle, tag)
    end
  end

end
