class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "LIST_GEAR_GROUPS") if !domain || !domain.hasAccess?(@cloud_user)

    app = Application.find(@cloud_user,app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "LIST_GEAR_GROUPS") unless app
    
    gear_states = app.show_state()
    group_instances = app.group_instances.map{ |group_inst| RestGearGroup.new(group_inst, gear_states, get_url, nolinks)}
    render_success(:ok, "gear_groups", group_instances, "LIST_GEAR_GROUPS",
                   "Showing gear groups for application '#{app_id}' with domain '#{domain_id}'")
  end
end
