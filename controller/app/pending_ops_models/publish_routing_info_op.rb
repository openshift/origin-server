class PublishRoutingInfoOp < PendingAppOp

  field :gear_id, type: String

  def execute
    get_gear.publish_routing_info
  end

  def rollback
    get_gear.unpublish_routing_info
  end
end
