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

    hot_deploy = get_bool(params[:hot_deploy].presence)
    force_clean_build = get_bool(params[:force_clean_build].presence)
    ref = params[:ref].presence
    artifact_url = params[:artifact_url].presence
    artifact_url = URI::encode(artifact_url) if artifact_url

    return render_error(:unprocessable_entity, "The ref is not well-formed. Git ref must be less than 256 characters. See also git-check-ref-format man page for rules.",
                          -1, "ref") if ref && (ref.length > 256 or ref !~ Deployment::GIT_REF_REGEX)

    return render_error(:unprocessable_entity, "Invalid Binary Artifact URL(#{artifact_url})",
                          -1, "artifact_url") if artifact_url && is_invalid_binary_artifact_url(artifact_url)

    return render_error(:unprocessable_entity, "Cannot specify a git deployment and a binary artifact deployment",
                          -1, "artifact_url") if artifact_url && ref

    return render_error(:unprocessable_entity, "Must specify a git deployment or a binary artifact deployment",
                          -1) unless artifact_url || ref

    return render_error(:unprocessable_entity, "The binary artifact provided is not compatible with the app deployment type, '#{@application.config['deployment_type']}'.",
                          -1, "artifact_url") if artifact_url && @application.config["deployment_type"] != "binary"

    return render_error(:unprocessable_entity, "The git ref provided is not compatible with the app deployment type, '#{@application.config['deployment_type']}'.",
                          -1, "ref") if ref && @application.config["deployment_type"] != "git"

    result = @application.deploy(hot_deploy, force_clean_build, ref, artifact_url)

    #@analytics_tracker.track_event("app_deploy", nil, @application)

    deployment = @application.deployments.sort_by {|deployment| deployment.activations.last ? deployment.activations.last : 0 }.last
    rest_deployment = get_rest_deployment(deployment)
    render_success(:created, "deployment", rest_deployment, "Added #{deployment.deployment_id} to application #{@application.name}", result)
  end

  # Return false if the artifact url passes all validation checks
  def is_invalid_binary_artifact_url(new_artifact_url)
    begin
      screening_url = URI(new_artifact_url)
      if ["http", "https", "ftp"].include?(screening_url.scheme)
        case
          when screening_url.path.slice(-4, 4) == ".tgz"
            return false
          when screening_url.path.slice(-7, 7) == ".tar.gz"
            return false
          else
            return true
        end
      else
        return true
      end
    rescue
      return true
    end
  end

  def update
    authorize! :update_deployments, @application
    deployments = params[:deployments].presence
    if deployments
      deploys = []
      deployments.each do |d|
        artifact_url = d["artifact_url"] ? URI::encode(d["artifact_url"]) : nil
        deploys.push(Deployment.new(deployment_id: d["id"],
                            created_at: Time.at(d["created_at"].to_f),
                                   ref: d["ref"],
                                  sha1: d["sha1"],
                          artifact_url: artifact_url,
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
