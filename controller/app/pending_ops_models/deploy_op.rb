class DeployOp < PendingAppOp

  field :hot_deploy, type: Boolean
  field :force_clean_build, type: Boolean
  field :ref, type: String
  field :artifact_url, type: String

  def execute
    gear = get_gear()
    gear.deploy(hot_deploy, force_clean_build, ref, artifact_url)
  end

end
