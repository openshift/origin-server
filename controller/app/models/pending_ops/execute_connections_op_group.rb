class ExecuteConnectionsOpGroup < PendingAppOpGroup

  def elaborate(app)
    pending_ops.push ExecuteConnectionsOp.new()
  end

end
