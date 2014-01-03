class DeleteAppOpGroup < PendingAppOpGroup

  def elaborate(app)
  end

  def execute(result_io=nil)
    self.application.delete
    self.application.pending_op_groups.clear
  end
end
