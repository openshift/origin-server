class NotifyAppDeleteOp < PendingAppOp

  def execute
    OpenShift::RoutingService.notify_delete_application pending_app_op_group.application
  end

end
