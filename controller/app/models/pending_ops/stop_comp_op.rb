class StopCompOp < PendingAppOp

  field :comp_spec, type: Hash, default: {}
  field :force, type: Boolean, default: false

  field :group_instance_id, type: String
  field :gear_id, type: String

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.removed
      component_instance = get_component_instance()

      tag = { "op_id" => self._id.to_s }
      if force and force == true
        job = gear.get_force_stop_job(component_instance)
      else
        job = gear.get_stop_job(component_instance)
      end
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

end
