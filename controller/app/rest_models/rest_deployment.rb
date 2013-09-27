class RestDeployment < OpenShift::Model
  attr_accessor :id, :created_at, :state, :hot_deploy, :force_clean_build, :ref, :sha1, :artifact_url, :activations

  def initialize(deployment)
    [:created_at, :state, :hot_deploy, :force_clean_build, :ref, :sha1, :artifact_url, :activations].each{ |sym| self.send("#{sym}=", deployment.send(sym)) }
    @id = deployment.deployment_id
    @created_at = Time.at(deployment.created_at) unless deployment.created_at.nil?
  end

  def to_xml(options={})
    options[:tag_name] = "deployment"
    super(options)
  end
end
