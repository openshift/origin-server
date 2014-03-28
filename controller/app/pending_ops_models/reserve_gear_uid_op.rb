class ReserveGearUidOp < PendingAppOp

  field :gear_id, type: String
  field :gear_size, type: String

  def execute
    get_gear.reserve_uid(gear_size)
  end

  def rollback
    get_gear.unreserve_uid
  end
end
