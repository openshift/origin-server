class RestDeployment < OpenShift::Model
  attr_accessor :id, :created_at, :state, :description, :hot_deploy, :force_clean_build, :ref, :artifact_url

  def initialize(deployment)
    [:id, :created_at, :state, :description, :hot_deploy, :force_clean_build, :ref, :artifact_url].each{ |sym| self.send("#{sym}=", deployment.send(sym)) }
  end

  def to_xml(options={})
    options[:tag_name] = "deployment"
    super(options)
  end
end
