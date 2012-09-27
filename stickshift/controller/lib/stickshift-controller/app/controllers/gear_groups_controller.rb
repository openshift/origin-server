class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
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
  
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "GET_GEAR_GROUP") if !domain || !domain.hasAccess?(@cloud_user)

    app = Application.find(@cloud_user,app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "GET_GEAR_GROUP") unless app
                        
    selected_gear_group = GroupInstance.get(app, gear_group_id)
    return render_error(:not_found, "Gear group '#{gear_group_id}' for application '#{app_id}' not found",
                        163, "GET_GEAR_GROUP") unless selected_gear_group
    
    gear_states = app.show_state()
    group = RestGearGroup.new(selected_gear_group, gear_states, get_url, nolinks)
    render_success(:ok, "gear_group", group, "GET_GEAR_GROUP",
                   "Showing gear group '#{app_id}' for application '#{app_id}' with domain '#{domain_id}'")
  end
  
  def update
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:id]
    storage = params[:storage]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "UPDATE_GEAR_GROUP") if !domain || !domain.hasAccess?(@cloud_user)

    app = Application.find(@cloud_user,app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "UPDATE_GEAR_GROUP") unless app
                        
    selected_gear_group = GroupInstance.get(app, gear_group_id)
    return render_error(:not_found, "Gear group '#{gear_group_id}' for application '#{app_id}' not found",
                        163, "UPDATE_GEAR_GROUP") unless selected_gear_group
                
    #only update attributes that are specified                  
    if storage
      max_storage = @cloud_user.capabilities['max_storage_per_gear']
      return render_format_error(:forbidden, "User is not allowed to change storage quota", 164,
                                 "UPDATE_GEAR_GROUP") unless max_storage
      num_storage = nil
      begin 
        num_storage = Integer(storage)
      rescue => e
        return render_format_error(:unprocessable_entity, "Invalid storage value provided.", 165, "UPDATE_GEAR_GROUP", "storage")
      end
      # find the minimum block size for the gear profile - use any gear in the group
      min_storage = selected_gear_group.get_cached_min_storage_in_gb()
      return render_format_error(:unprocessable_entity, "Storage value must be between #{min_storage} and #{max_storage}", 166,
                                   "UPDATE_GEAR_GROUP") if (num_storage < min_storage) or (num_storage > max_storage)
      begin
        selected_gear_group.set_quota(num_storage)
        app.save
      rescue Exception => e
        return render_format_exception(e, "UPDATE_GEAR_GROUP")
      end             
    end
    
    if max_scale
                    
    end
    
    if min_scale
                    
    end

    gear_states = app.show_state()
    group = RestGearGroup.new(selected_gear_group, gear_states, get_url, nolinks)
    render_success(:ok, "gear_group", group, "UPDATE_GEAR_GROUP",
                   "Showing gear group '#{app_id}' for application '#{app_id}' with domain '#{domain_id}'")
  end
end
