class RestDeployment < OpenShift::Model
  attr_accessor :id, :created_at, :state, :hot_deploy, :force_clean_build, :ref, :artifact_url

  def initialize(deployment)
    [:created_at, :state, :hot_deploy, :force_clean_build, :ref, :artifact_url].each{ |sym| self.send("#{sym}=", deployment.send(sym)) }
    @id = deployment.deployment_id
  end

  def to_xml(options={})
    options[:tag_name] = "deployment"
    super(options)
  end
end
