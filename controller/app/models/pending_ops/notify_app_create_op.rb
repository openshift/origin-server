class NotifyAppCreateOp < PendingAppOp

  def execute
    OpenShift::RoutingService.notify_create_application application
  end

end
