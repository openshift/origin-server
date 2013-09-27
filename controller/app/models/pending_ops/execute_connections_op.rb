class ExecuteConnectionsOp < PendingAppOp

  def execute
    pending_app_op_group.application.execute_connections rescue nil
  end

  def rollback
    pending_app_op_group.application.execute_connections rescue nil
  end

end
