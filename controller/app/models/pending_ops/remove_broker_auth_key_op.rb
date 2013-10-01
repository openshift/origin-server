class RemoveBrokerAuthKeyOp < PendingAppOp

  field :group_instance_id, type: String
  field :gear_id, type: String

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.node_removed
      job = gear.get_broker_auth_key_remove_job()
      tag = { "op_id" => self._id.to_s }
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

end
