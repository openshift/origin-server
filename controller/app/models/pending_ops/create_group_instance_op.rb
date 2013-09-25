class CreateGroupInstanceOp < PendingAppOp

  field :group_instance_id, type: String

  def execute(skip_node_ops=false)
    pending_app_op_group.application.group_instances.push(GroupInstance.new(custom_id: group_instance_id))
  end
  
  def rollback(skip_node_ops=false)
    begin
      group_instance = get_group_instance()
      group_instance.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
