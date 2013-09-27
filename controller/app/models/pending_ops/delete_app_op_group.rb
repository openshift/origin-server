class DeleteAppOpGroup < PendingAppOpGroup

  def elaborate(app)
  end
  
  def execute(result_io=nil, skip_node_ops=false)
    self.application.delete
    self.application.pending_op_groups.clear
  end

end
