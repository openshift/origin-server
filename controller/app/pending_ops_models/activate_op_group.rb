class ActivateOpGroup < PendingAppOpGroup

  field :deployment_id, type: String

  def elaborate(app)
    if app.gears.where(app_dns: true).count > 0
      gear = app.gears.find_by(app_dns: true)
      pending_ops.push ActivateOp.new(gear_id: gear.id.to_s, deployment_id: deployment_id)
    end
  end

end
