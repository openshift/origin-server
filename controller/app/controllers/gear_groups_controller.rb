class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  # GET /domains/[domain_id]/applications/[application_id]/gear_groups
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "LIST_GEAR_GROUPS") if !domain || !domain.hasAccess?(@cloud_user)

    @domain_name = domain.namespace
    app = Application.find(@cloud_user,app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "LIST_GEAR_GROUPS") unless app
    
    @application_name = app.name
    @application_uuid = app.uuid
    gear_states = app.show_state()
    group_instances = app.group_instances.map{ |group_inst| RestGearGroup.new(group_inst, gear_states, get_url, nolinks)}
    render_success(:ok, "gear_groups", group_instances, "LIST_GEAR_GROUPS",
                   "Showing gear groups for application '#{app_id}' with domain '#{domain_id}'")
  end
  
  # GET /domains/[domain_id]/applications/[application_id]/gear_groups/[id]
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "GET_GEAR_GROUP") if !domain || !domain.hasAccess?(@cloud_user)

    @domain_name = domain.namespace
    app = Application.find(@cloud_user,app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "GET_GEAR_GROUP") unless app
                        
    @application_name = app.name
    @application_uuid = app.uuid
    selected_gear_group = GroupInstance.get(app, gear_group_id)
    return render_error(:not_found, "Gear group '#{gear_group_id}' for application '#{app_id}' not found",
                        163, "GET_GEAR_GROUP") unless selected_gear_group
    
    gear_states = app.show_state()
    group = RestGearGroup.new(selected_gear_group, gear_states, get_url, nolinks)
    render_success(:ok, "gear_group", group, "GET_GEAR_GROUP",
                   "Showing gear group '#{app_id}' for application '#{app_id}' with domain '#{domain_id}'")
  end
end
