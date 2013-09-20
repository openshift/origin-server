class UpdateClusterOp < PendingAppOp

  def execute
    pending_app_op_group.application.update_cluster
  end

end
