class MakeAppHaOpGroup < PendingAppOpGroup

  def elaborate(app)
    app.gears.each do |gear|
      pending_ops.push PublishRoutingInfoOp.new(gear_id: gear._id.to_s)
    end
    pending_ops.push RegisterRoutingDnsOp.new()
  end

end
