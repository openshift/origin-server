class TidyAppOpGroup < PendingAppOpGroup

  def elaborate(app)
    ops = []
    app.gears.each do |gear|
      ops.push(TidyCompOp.new(gear_id: gear._id.to_s))
    end
    pending_ops.push(*ops)
  end

end
