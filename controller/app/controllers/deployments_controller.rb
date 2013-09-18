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
    Rails.logger.error "ALL #{@application.deployments}"
    deployment_id = params[:id].presence
    Rails.logger.error "Getting deployment #{deployment_id}"

    deployment = @application.deployments.find_by(deployment_id: deployment_id)
    Rails.logger.error "Got deployment #{deployment.inspect}"
    render_success(:ok, "deployment", get_rest_deployment(deployment), "Showing deployment #{deployment_id} for application #{@application.name} under domain #{@application.domain_namespace}")
  end


  def create
    #if there is a deployment parameter call update
    return update if params[:deployments].presence

    #TODO implement :create_deployment
    #authorize! :create_deployment, @application

    hot_deploy = params[:hot_deploy].presence || false
    force_clean_build = params[:force_clean_build].presence || false
    ref = params[:ref].presence
    artifact_url = params[:artifact_url].presence

    deployment = Deployment.new(hot_deply: hot_deploy, force_clean_build: force_clean_build, ref: ref, artifact_url: artifact_url)
    if deployment.invalid?
      messages = get_error_messages(deployment)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    else
      result = @application.deploy(deployment)
      rest_deployment = get_rest_deployment(@application.deployments.last)
      render_success(:created, "deployment", rest_deployment, "Added #{deployment.deployment_id} to application #{@application.name}", result)
    end
  end

  def update
    #TODO implement :update_deployments
    #authorize! :update_deployments, @application
    deployments = params[:deployments].presence
    if deployments
      deploys = []
      deployments.each do |d|
        deploys.push(Deployment.new(deployment_id: d["id"],
                                 state: d["state"],
                            created_at: d["created_at"],  #TODO:  Need to figure out the transfer format here.  time_in_millis is probably best
                                   ref: d["ref"],
                          artifact_url: d["artifact_url"],
                            hot_deploy: d["hot_deploy"],
                     force_clean_build: d["force_clean_build"]))
      end
      @application.update_deployments(deploys)
      @application.reload
    end
    rest_deployments = @application.deployments.map{ |d| get_rest_deployment(d) }
    render_success(:ok, "deployments", rest_deployments, "Updated deployments for application #{@application.name} under domain #{@application.domain_namespace}")
  end
end
