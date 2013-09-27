class ReserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String

  def execute
    gear = get_gear()
    gear.reserve_uid
  end
  
  def rollback
    gear = get_gear()
    gear.unreserve_uid
  end

end
