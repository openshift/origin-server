class ApplicationJobsController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :job

  def index
    rest_jobs = @application.aliases.map{ |a| get_rest_job(a) }
    render_success(:ok, "aliases", rest_aliases, "Listing aliases for application #{@application.name} under domain #{@application.domain_namespace}")
  end

  def show
    id = params[:id].downcase if params[:id].presence

    job = JobState.find_by(_id: id)
    render_success(:ok, "job", get_rest_job(@application, job), "Showing job #{id} for application #{@application.name}")
  end

  def destroy
    #authorize! :destroy_app_job, @job

    job_id = params[:id].downcase if params[:id].presence
    result = JobState.destroy_all(_id: job_id)

    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed job #{job_id} from application #{@application.name}", result)
  end
end
