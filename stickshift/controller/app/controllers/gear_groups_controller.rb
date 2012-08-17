class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_GEAR_GROUPS")
    end
    
    begin
      application = Application.find_by(domain: domain, name: app_id)
      
      gear_states = application.get_gear_states()
      group_instances = application.group_instances.map{ |group_inst| RestGearGroup.new(group_inst, gear_states, get_url, nolinks)}
      render_success(:ok, "gear_groups", group_instances, "LIST_GEAR_GROUPS", "Showing gear groups for application '#{app_id}' with domain '#{domain_id}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'", 101, "LIST_GEAR_GROUPS")
    end
  end
end
