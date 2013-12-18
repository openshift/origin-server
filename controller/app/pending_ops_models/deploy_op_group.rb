class DeployOpGroup < PendingAppOpGroup

  field :hot_deploy, type: Boolean
  field :force_clean_build, type: Boolean
  field :ref, type: String
  field :artifact_url, type: String

  def elaborate(app)
    if app.gears.where(app_dns: true).count > 0
      gear = app.gears.find_by(app_dns: true)
      pending_ops.push DeployOp.new(gear_id: gear.id.to_s, hot_deploy: hot_deploy, force_clean_build: force_clean_build, ref: ref, artifact_url: artifact_url)
    end
  end

end
