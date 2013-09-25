class ReserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute(skip_node_ops=false)
    gear = get_gear()
    gear.reserve_uid
  end
  
  def rollback(skip_node_ops=false)
    gear = get_gear()
    gear.unreserve_uid
  end

end
