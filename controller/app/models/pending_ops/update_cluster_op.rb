class UpdateClusterOp < PendingAppOp

  def execute
    pending_app_op_group.application.update_cluster
  end

  def rollback
    begin
      pending_app_op_group.application.update_cluster(rollback: true)
    rescue => e
      Rails.logger.error "Rolling back update_cluster failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

end
