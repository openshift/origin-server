class NotifyAppDeleteOp < PendingAppOp

  def execute
    OpenShift::RoutingService.notify_delete_application application
  end

end
