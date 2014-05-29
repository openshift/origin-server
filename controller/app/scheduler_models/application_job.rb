# Model for backgrounded application jobs.
class ApplicationJob

  include Backburner::Performable
  include Backburner::Queue
  
  queue "application" # defaults to 'application-job'
  queue_priority 100 # most urgent priority is 0
  
  # Performs the backgrounded job.
  def self.execute_job(app_id)
    app = nil
    result_io = nil
    Rails.logger.info "Processing job for application with ID '#{app_id}'"
    begin
      begin 
        app = Application.find_by(:_id => app_id)
      rescue Mongoid::Errors::DocumentNotFound
        # capturing and ignoring this exception after logging
        # if the application is not found, then the job can be deleted
        Rails.logger.info "Application with ID '#{app_id}' not found while trying to execute backgrounded job for it"
        return
      end

      Lock.run_in_app_lock(app) do
        result_io = ResultIO.new
        app.run_job(result_io)
      end unless app.nil?
    rescue OpenShift::LockUnavailableException
      # capturing and ignoring this exception after logging
      # if the application is not found, then the job can be deleted
      Rails.logger.info "Application with UUID #{app_id} not found while trying to execute backgrounded job for it"
      return
    end
    result_io
  end
  
  # handle job execution errors
  def self.on_error(ex)
    if ex.kind_of? OpenShift::LockUnavailableException
      ApplicationJob.async(:queue => "application", :delay => 5.seconds).execute_job(ex.app_id)
    end
  end
end
