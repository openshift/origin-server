class MakeAppHaOpGroup < PendingAppOpGroup

  def elaborate(app)
    app.group_instances.each { |gi|
      gi.gears.each { |gear|
        pending_ops.push PublishRoutingInfoOp.new(group_instance_id: gi._id.to_s, gear_id: gear._id.to_s)
      }
    }
    pending_ops.push RegisterRoutingDnsOp.new()
  end

end
