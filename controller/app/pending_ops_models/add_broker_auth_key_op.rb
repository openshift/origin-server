class AddBrokerAuthKeyOp < PendingAppOp

  # the iv and token fields will be removed from this pending_op
  # they are maintained for now to ensure compatibility for any in-flight operations 
  field :iv, type: String
  field :token, type: String
  field :gear_id, type: String

  def is_parallel_executable
    return true
  end

  def add_parallel_execute_job(handle)
    gear = get_gear()
    unless gear.removed
      if iv.nil? or token.nil?
        iv, token = OpenShift::Auth::BrokerKey.new.generate_broker_key(application)
      end
      job = gear.get_broker_auth_key_add_job(iv, token)
      tag = { "op_id" => self._id.to_s }
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

end
