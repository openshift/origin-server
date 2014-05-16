class RestJob < OpenShift::Model
  attr_accessor :id, :state, :completion_state, :retry_count, :rollback_retry_count, 
                :percentage_complete, :properties, :messages, :info, 
                :data, :user_actionable_error, :exit_code, :links

  def initialize(job, resource, url, nolinks=false)
    self.id = job.id
    self.state = job.state
    self.completion_state = job.completion_state
    self.retry_count = job.retry_count
    self.rollback_retry_count = job.rollback_retry_count
    self.percentage_complete = job.percentage_complete
    self.properties = job.properties

    self.messages = {}
    self.messages["debug"] = job.output_debug.join("\n") if job.output_debug.present?
    self.messages["result"] = job.output_result.join("\n") if job.output_result.present?
    self.messages["info"] = job.output_message.join("\n") if job.output_message.present?
    self.messages["error"] = job.output_error.join("\n") if job.output_error.present?

    self.info = job.output_info.join("\n") if job.output_info.present?
    self.data = job.output_data if job.output_data.present?
    self.user_actionable_error = job.hasUserActionableError if job.state == :complete and job.completion_state == :failed
    self.exit_code = job.exitcode if job.state == :complete

 
    unless nolinks
      resource_url = nil
      case resource.class
      when Application
        resource_url = "application/#{resource._id}"
      when Domain
        resource_url = "domain/#{resource._id}"
      when CloudUser
        resource_url = "user/#{resource._id}"
      end
      
      self.links = {
        "GET" => Link.new("Get job", "GET", URI::join(url, "job/#{self.id}")),
        "DELETE" => Link.new("Delete job", "DELETE", URI::join(url, "job/#{self.id}")),
        "GET_RESOURCE" => Link.new("Get resource", "GET", URI::join(url, "#{resource_url}"))
      }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "job"
    super(options)
  end
end
