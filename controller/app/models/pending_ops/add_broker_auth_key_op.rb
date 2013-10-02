class AddBrokerAuthKeyOp < PendingAppOp

  field :iv, type: String
  field :token, type: String
  field :group_instance_id, type: String
  field :gear_id, type: String

  def isParallelExecutable()
    return true
  end

  def addParallelExecuteJob(handle)
    gear = get_gear()
    unless gear.removed
      job = gear.get_broker_auth_key_add_job(iv, token)
      tag = { "op_id" => self._id.to_s }
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

end
