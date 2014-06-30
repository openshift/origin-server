class ReserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :gear_size, type: String
  field :region_id, type: Moped::BSON::ObjectId 

  def execute
    get_gear.reserve_uid(gear_size, region_id)
  end

  def rollback
    get_gear.unreserve_uid
  end
end
