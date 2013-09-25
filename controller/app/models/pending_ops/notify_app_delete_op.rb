class NotifyAppDeleteOp < PendingAppOp

  def execute(skip_node_ops=false)
    OpenShift::RoutingService.notify_delete_application pending_app_op_group.application
  end

end
