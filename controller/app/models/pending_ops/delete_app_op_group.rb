class DeleteAppOpGroup < PendingAppOpGroup

  def elaborate(app)
    
  end
  
  def execute(result_io)
    self.application.delete
    self.application.pending_op_groups.clear
  end

end
