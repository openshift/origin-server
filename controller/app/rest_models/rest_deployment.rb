class RestDeployment < OpenShift::Model
  attr_accessor :id, :created_at, :hot_deploy, :force_clean_build, :ref, :sha1, :artifact_url, :activations

  def initialize(deployment)
    [:created_at, :hot_deploy, :force_clean_build, :ref, :sha1, :artifact_url].each{ |sym| self.send("#{sym}=", deployment.send(sym)) }
    @id = deployment.deployment_id
    @activations = deployment.activations.map { |activation| Time.at(activation).utc.iso8601 }
  end

  def to_xml(options={})
    options[:tag_name] = "deployment"
    super(options)
  end
end
