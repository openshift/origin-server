class ApplicationJobsController < JobsController
  include RestModelHelper
  action_log_tag_resource :job
  
  protected
    def resource
      @resource ||= get_application
    end
  
end
