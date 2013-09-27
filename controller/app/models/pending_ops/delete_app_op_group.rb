class DeleteAppOpGroup < PendingAppOpGroup

  def elaborate(app)
  end
  
  def execute(result_io=nil, skip_node_ops=false)
    # do not change the order of delete,pending_op_groups.clear
    # because clearing pending_ops cleans up 'self'
    self.application.delete
    self.application.pending_op_groups.clear
  end

end
