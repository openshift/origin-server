class DescriptorsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      log_action(@request_id, @cloud_user._id.to_s, @cloud_user.login, "LIST_APPLICATIONS", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_DESCRIPTOR") if !domain || !domain.hasAccess?(@cloud_user)
    end
    
    begin
      application = Application.find_by(domain: domain, name: application_id)
      render_success(:ok, "descriptor", application.to_descriptor.to_yaml, "SHOW_DESCRIPTOR", "Show descriptor for application '#{application_id}' for domain '#{domain_id}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_DESCRIPTOR") unless application
    end
  end
end
