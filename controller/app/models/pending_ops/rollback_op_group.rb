class RollbackOpGroup < PendingAppOpGroup

  field :deployment_id, type: String

  def elaborate(app)
    app.group_instances.each do |group_instance|
      if group_instance.gears.where(app_dns: true).count > 0
        gear = group_instance.gears.find_by(app_dns: true)
        pending_ops.push DeployOp.new(group_instance_id: group_instance.id.to_s, gear_id: gear.id.to_s, deployment_id: deployment_id)
        break
      end
    end
  end

end
