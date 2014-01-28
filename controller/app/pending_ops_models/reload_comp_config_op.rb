class ReloadCompConfigOp < PendingAppOp

  field :comp_spec, type: ComponentSpec, default: {}
  field :gear_id, type: String

  def is_parallel_executable
    return true
  end

  def add_parallel_execute_job(handle)
    gear = get_gear()
    unless gear.removed
      component_instance = get_component_instance()
      job = gear.get_reload_job(component_instance)
      tag = { "op_id" => self._id.to_s }
      RemoteJob.add_parallel_job(handle, tag, gear, job)
    end
  end

end
