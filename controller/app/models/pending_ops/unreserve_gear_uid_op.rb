class UnreserveGearUidOp < PendingAppOp

  field :gear_id, type: String

  def execute
    gear = get_gear()
    gear.unreserve_uid
  end

end
