class ReserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :gear_size, type: String

  def execute
    gear = get_gear()
    gear.reserve_uid(gear_size)
  end
  
  def rollback
    gear = get_gear()
    gear.unreserve_uid
  end

end
