class StartCompOp < PendingAppOp

  field :comp_spec, type: Hash, default: {}
  field :gear_id, type: String

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.removed
      component_instance = get_component_instance()
      job = gear.get_start_job(component_instance)
      tag = { "op_id" => self._id.to_s }
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

  def action_message
    "A gear start did not complete"
  end
end
