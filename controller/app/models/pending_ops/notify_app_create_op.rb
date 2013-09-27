class NotifyAppCreateOp < PendingAppOp

  def execute
    OpenShift::RoutingService.notify_create_application pending_app_op_group.application
  end

end
