class GearGroupResourcesController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def show
    index
  end
  
  # GET /domains/[domain-id]/applications/[application_id]/gear_groups/[id]/resources
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:gear_group_id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "LIST_GEAR_GROUP_RESOURCES") if !domain || !domain.hasAccess?(@cloud_user)

    app = Application.find(@cloud_user, app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "LIST_GEAR_GROUP_RESOURCES") unless app
    
    selected_gear_group = GroupInstance.get(app, gear_group_id)
      
    return render_error(:not_found, "Gear group '#{gear_group_id}' for application '#{app_id}' not found",
                        163, "LIST_GEAR_GROUP_RESOURCES") unless selected_gear_group

    quota = selected_gear_group.get_quota
    render_success(:ok, "resources", RestGearGroupResources.new(selected_gear_group.uuid, quota[:storage]), "UPDATE_GEAR_GROUP_RESOURCES")
  end

  # PUT /domains/[domain-id]/applications/[application_id]/gear_groups/[id]/resources
  def update
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:gear_group_id]
    storage = params[:storage]
    
    num_storage = nil
    max_storage = @cloud_user.capabilities['max_storage_per_gear']
    return render_error(:not_found, "User is not allowed to change storage quota", 164,
                        "UPDATE_GEAR_GROUP_RESOURCES") unless max_storage
    
    begin 
      num_storage = Integer(storage)
    rescue => e
      return render_error(:not_found, "Invalid storage value provided.", 165, "UPDATE_GEAR_GROUP_RESOURCES", "storage")
    end
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "UPDATE_GEAR_GROUP_RESOURCES") if !domain || !domain.hasAccess?(@cloud_user)

    app = Application.find(@cloud_user, app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "UPDATE_GEAR_GROUP_RESOURCES") unless app
    
    selected_gear_group = GroupInstance.get(app, gear_group_id)
    
    return render_error(:not_found, "Gear group '#{gear_group_id}' for application '#{app_id}' not found",
                        163, "UPDATE_GEAR_GROUP_RESOURCES") unless selected_gear_group
    begin
      # find the minimum block size for the gear profile - use any gear in the group
      min_storage = selected_gear_group.get_cached_min_storage_in_gb()
      return render_error(:not_found, "Storage value must be between #{min_storage} and #{max_storage}", 166,
                          "UPDATE_GEAR_GROUP_RESOURCES") if (num_storage < min_storage) or (num_storage > max_storage)
      selected_gear_group.set_quota(num_storage)
      app.save
    rescue Exception => e
      return render_exception(e, "UPDATE_GEAR_GROUP_RESOURCES")
    end
    
    resources = RestGearGroupResources.new(selected_gear_group.uuid, selected_gear_group.get_quota()[:storage])
    render_success(:ok, "resources", resources, "UPDATE_GEAR_GROUP_RESOURCES",
                   "Updating resources for group '#{gear_group_id}' for application '#{app_id}'")
  end
end
