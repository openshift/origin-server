class PublishRoutingInfoOp < PendingAppOp

  field :gear_id, type: String

  def execute
    gear = get_gear()
    gear.publish_routing_info
  end

end
