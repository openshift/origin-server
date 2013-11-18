class ExecuteConnectionsOp < PendingAppOp

  def execute
    application.execute_connections rescue nil
  end

  def rollback
    application.execute_connections rescue nil
  end

end
