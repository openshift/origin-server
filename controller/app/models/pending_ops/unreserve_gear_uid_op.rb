class UnreserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute(skip_node_ops=false)
    gear = get_gear()
    gear.unreserve_uid
  end

end
