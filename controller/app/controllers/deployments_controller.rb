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
    id = params[:id].presence
    Rails.logger.error "Getting deployemt #{id}"

    deployment = @application.deployments.find_by(id: id)
    Rails.logger.error "Got deployemt #{deployment.inspect}"
    render_success(:ok, "deployment", get_rest_deployment(deployment), "Showing deployment #{id} for application #{@application.name} under domain #{@application.domain_namespace}")
  end


  def create
    #if there is a deployment parameter call update
    return update if params[:deployments].presence

    #TODO implement :create_deployment
    #authorize! :create_deployment, @application

    description = params[:description].presence
    hot_deploy = params[:hot_deploy].presence || false
    force_clean_build = params[:force_clean_build].presence || false
    git_branch = params[:git_branch].presence
    git_commit_id = params[:git_commit_id].presence
    git_tag = params[:git_tag].presence
    artifact_url = params[:artifact_url].presence

    deployment = Deployment.new(description: description, hot_deply: hot_deploy, force_clean_build: force_clean_build, git_branch: git_branch, git_commit_id: git_commit_id, git_tag: git_tag, artifact_url: artifact_url)
    if deployment.invalid?
      messages = get_error_messages(deployment)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    else
       result, id = @application.add_deployment(deployment)
       rest_deployment = get_rest_deployment(@application.deployments.find_by(id: id))
       render_success(:created, "deployment", rest_deployment, "Added #{deployment.id} to application #{@application.name}", result)
    end
  end

  def update
    #TODO implement :update_deployments
    #authorize! :update_deployments, @application
    deployments = params[:deployments].presence
    if deployments
      deploys = []
      deployments.each do |d|
        deploys.push(Deployment.new(id: d["id"],
                                 state: d["state"],
                            created_at: d["created_at"],
                           description: d["description"],
                            git_branch: d["git_branch"],
                         git_commit_id: d["git_commit_id"],
                               git_tag: d["git_tag"],
                          artifact_url: d["artifcat_url"],
                            hot_deploy: d["hot_deploy"],
                     force_clean_build: d["force_clean_build"]))
      end
      @application.update_deployments(deploys)
    end
    rest_deployments = @application.deployments.map{ |d| get_rest_deployment(d) }
    render_success(:ok, "deployments", rest_deployments, "Updated deployments for application #{@application.name} under domain #{@application.domain_namespace}")
  end
end
