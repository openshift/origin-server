class JobsController < BaseController
  include RestModelHelper
  action_log_tag_resource :job

  def index
    jobs = JobState.accessible(current_user)
    if params[:owner].presence and params[:owner].presence == "@self"
      jobs = jobs.where(owner_id: current_user.id)
    end
    if resource
      jobs = jobs.where(resource_id: resource.id)
    end
    rest_jobs = jobs.map{ |j| get_rest_job(j) }
    render_success(:ok, "jobs", rest_jobs, "Listing #{rest_jobs.count} job(s)")
  end

  def show
    id = params[:id].presence
    job = JobState.accessible(current_user).find(id)
    render_success(:ok, "job", get_rest_job(job), "Showing job #{id}")
  end

  def destroy
    id = params[:id].downcase
    job = JobState.accessible(current_user).find(id)
    authorize! :destroy, job
    result = JobState.destroy_all(_id: job.id)
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed job #{id}", result)
  end
  
  protected
    def resource
      nil
    end
  
end
