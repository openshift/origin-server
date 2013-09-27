class UnsubscribeConnectionsOp < PendingAppOp

  field :sub_pub_info, type: Hash, default: {}
  
  def execute
    pending_app_op_group.application.unsubscribe_connections(sub_pub_info)
  end

end
