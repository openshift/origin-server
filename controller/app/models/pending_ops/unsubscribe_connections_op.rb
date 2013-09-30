class UnsubscribeConnectionsOp < PendingAppOp

  field :sub_pub_info, type: Hash, default: {}
  
  def execute(skip_node_ops=false)
    pending_app_op_group.application.unsubscribe_connections(sub_pub_info) unless skip_node_ops
  end

end
