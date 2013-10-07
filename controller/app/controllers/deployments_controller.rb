class DeploymentsController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :deployment

  def index
    force_refresh = params[:force_refresh] || false
    @application.refresh_deployments if force_refresh

    rest_deployments = @application.deployments.map{ |d| get_rest_deployment(d) }
    render_success(:ok, "deployments", rest_deployments, "Listing deployments for application #{@application.name} under domain #{@application.domain_namespace}")
  end

  def show
    deployment_id = params[:id].presence

    deployment = @application.deployments.find_by(deployment_id: deployment_id)
    return render_error(:not_found, "Could not find deployment #{deployment_id} for application #{@application.name}", nil, "SHOW_DEPLOYMENT") if deployment.nil?
    render_success(:ok, "deployment", get_rest_deployment(deployment), "Showing deployment #{deployment_id} for application #{@application.name} under domain #{@application.domain_namespace}")
  end


  def create
    #if there is a deployment parameter call update
    return update if params[:deployments].presence
    authorize! :create_deployment, @application

    hot_deploy = params[:hot_deploy].presence || false
    force_clean_build = params[:force_clean_build].presence || false
    ref = params[:ref].presence
    artifact_url = params[:artifact_url].presence

    return render_error(:unprocessable_entity, "Git ref must be less than 256 characters",
                          105, "name") if ref && ref.length > 256

    result = @application.deploy(hot_deploy, force_clean_build, ref, artifact_url)
    deployment = @application.deployments.last
    rest_deployment = get_rest_deployment(deployment)
    render_success(:created, "deployment", rest_deployment, "Added #{deployment.deployment_id} to application #{@application.name}", result)
  end

  def update
    authorize! :update_deployments, @application
    deployments = params[:deployments].presence
    if deployments
      deploys = []
      deployments.each do |d|
        deploys.push(Deployment.new(deployment_id: d["id"],
                            created_at: Time.at(d["created_at"].to_f),
                                   ref: d["ref"],
                                  sha1: d["sha1"],
                          artifact_url: d["artifact_url"],
                           activations: d["activations"] ? d["activations"].map(&:to_f) : [],
                            hot_deploy: d["hot_deploy"] || false,
                     force_clean_build: d["force_clean_build"] || false))
      end
      @application.update_deployments(deploys)
      @application.reload
    end
    rest_deployments = @application.deployments.map{ |d| get_rest_deployment(d) }
    render_success(:ok, "deployments", rest_deployments, "Updated deployments for application #{@application.name} under domain #{@application.domain_namespace}")
  end
end
