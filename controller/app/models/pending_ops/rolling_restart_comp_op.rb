class RollingRestartCompOp < RestartCompOp

  def addParallelExecuteJob(handle)
    gear = get_gear()
    component_instance = get_component_instance()
    job = gear.get_restart_job(component_instance, true)
    tag = { "op_id" => self._id.to_s }
    RemoteJob.add_parallel_job(handle, tag, gear, job)
  end

end
