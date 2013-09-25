class ExecuteConnectionsOp < PendingAppOp

  def execute(skip_node_ops=false)
    unless skip_node_ops
      pending_app_op_group.application.execute_connections rescue nil
    end
  end

  def rollback(skip_node_ops=false)
    unless skip_node_ops
      pending_app_op_group.application.execute_connections rescue nil
    end
  end

end
