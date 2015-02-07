class NotifyAppCreateOp < PendingAppOp

  def execute
    OpenShift::RoutingService.notify_create_application application
  end

  def rollback
    OpenShift::RoutingService.notify_delete_application application
  end

end
