class EmbCartController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :app_cartridge

  def index
    cartridges = get_application_rest_cartridges(@application)
    render_success(:ok, "cartridges", cartridges, "Listing cartridges for application #{@application.name} under domain #{@application.domain_namespace}")
  end

  def show
    id = ComponentInstance.check_name!(params[:id].presence)
    status_messages = if_included(:status_messages, true)

    component = @application.component_instances.find_by(cartridge_name: id)

    cartridge = get_embedded_rest_cartridge(
      @application,
      component,
      component.group_instance.all_component_instances,
      @application.group_instances_with_overrides.detect{ |i| i.instance == component.group_instance },
      status_messages
    )
    render_success(:ok, "cartridge", cartridge, "Showing cartridge #{id} for application #{@application.name} under domain #{@application.domain_namespace}")
  end

  def create
    if @application.quarantined
      return render_upgrade_in_progress
    end

    authorize! :create_cartridge, @application

    user_env_vars = params[:environment_variables].presence
    Application.validate_user_env_variables(user_env_vars, true)

    specs = []
    if params[:cartridges].is_a?(Array)
      specs += params[:cartridges].map{ |p| p.is_a?(Hash) ? p : {name: String(p).presence}}
    elsif params[:cartridge].is_a? Hash
      specs << params[:cartridge]
    elsif params[:cartridge].is_a? String
      specs << params.merge(name: params[:cartridge]) # DEPRECATED
    else
      specs << params
    end
    CartridgeInstance.check_cartridge_specifications!(specs)
    return render_error(:unprocessable_entity, "Error in parameters. Cannot determine cartridge. Use 'cartridge'/'name'/'url'", 109) unless specs.all?{ |f| f[:name] or f[:url] or f[:id] }

    @application.domain.validate_gear_sizes!(specs.map{ |f| f[:gear_size] }.compact.uniq, "gear_size")

    cartridges = CartridgeCache.find_and_download_cartridges(specs)
    group_overrides = CartridgeInstance.overrides_for(cartridges, @application)
    @application.validate_cartridge_instances!(cartridges)

    if !Rails.configuration.openshift[:allow_obsolete_cartridges] && (obsolete = cartridges.select{ |c| !c.singleton? && c.obsolete }.presence)
      raise OpenShift::UserException.new("The following cartridges are no longer available: #{obsolete.map(&:name).to_sentence}", 109, "cartridges")
    end

    result = @application.add_cartridges(cartridges.map(&:cartridge), group_overrides, nil, user_env_vars)

    if @application.scalable
      @analytics_tracker.identify(@cloud_user.reload)
    end
    @analytics_tracker.track_event('cartridges_add', nil, @application, {'cartridges' => cartridges.map(&:name).join(', ')})

    overrides = @application.group_instances_with_overrides
    rest = cartridges.map do |cart|
      component = @application.component_instances.where(cartridge_name: cart.name).first
      get_embedded_rest_cartridge(
        @application,
        component,
        component.group_instance.all_component_instances,
        overrides.detect{ |i| i.instance == component.group_instance }
      )
    end

    if rest.length > 1
      render_success(:created, "cartridges", rest, "Added #{cartridges.map(&:name).to_sentence} to application #{@application.name}", result)
    else
      render_success(:created, "cartridge",rest.first, "Added #{cartridges.first.name} to application #{@application.name}", result)
    end

  rescue OpenShift::GearLimitReachedException => ex
    render_error(:unprocessable_entity, "Unable to add cartridge: #{ex.message}", 104)
  rescue OpenShift::UserException => ex
    ex.field = nil if ex.field == "cartridge"
    raise
  end

  def destroy
    if @application.quarantined
      return render_upgrade_in_progress
    end

    authorize! :destroy_cartridge, @application

    id = ComponentInstance.check_name!(params[:id].presence)
    instance = @application.component_instances.find_by(cartridge_name: id)
    result = @application.remove_cartridges([instance.cartridge_name])

    if @application.scalable
      @analytics_tracker.identify(@cloud_user.reload)
    end
    @analytics_tracker.track_event('cartridge_remove', nil, @application, {'cartridges' => id})

    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed #{id} from application #{@application.name}", result)
  end

  def update
    id = ComponentInstance.check_name!(params[:id].presence)

    scales_from = Integer(params[:scales_from].presence) rescue nil
    scales_to = Integer(params[:scales_to].presence) rescue nil
    additional_storage = params[:additional_gear_storage].presence

    if scales_from.nil? and scales_to.nil? and additional_storage.nil?
      return render_error(:unprocessable_entity, "No update parameters specified.  Valid update parameters are: scales_from, scales_to, additional_gear_storage", 168)
    end

    authorize!(:scale_cartridge, @application) unless scales_from.nil? and scales_to.nil?
    authorize!(:change_gear_quota, @application) unless additional_storage.nil?

    if additional_storage
      begin
        additional_storage = Integer(additional_storage)
      rescue
        return render_error(:unprocessable_entity, "Invalid storage value provided.", 165, "additional_storage")
      end
    end

    if !@application.scalable and ((scales_from and scales_from != 1) or (scales_to and scales_to != 1 and scales_to != -1))
      return render_error(:unprocessable_entity, "Application '#{@application.name}' is not scalable", 100, "name")
    end

    if scales_from and scales_from < 1
      return render_error(:unprocessable_entity, "Invalid scales_from factor #{scales_from} provided", 168, "scales_from")
    end

    if scales_to and (scales_to == 0 or scales_to < -1)
      return render_error(:unprocessable_entity, "Invalid scales_to factor #{scales_to} provided", 168, "scales_to")
    end

    if scales_to and scales_from and scales_to >= 1 and scales_to < scales_from
      return render_error(:unprocessable_entity, "Invalid scales_(from|to) factor provided", 168, "scales_to")
    end

    if @application.quarantined && (scales_from || scales_to)
      return render_upgrade_in_progress
    end

    instance = @application.component_instances.find_by(cartridge_name: id)
    if instance.is_sparse?
      if scales_to and scales_to != 1
        return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_to")
      elsif scales_from and scales_from != 1
        return render_error(:unprocessable_entity, "The cartridge #{id} cannot be scaled.", 168, "PATCH_APP_CARTRIDGE", "scales_from")
      end
    end

    override = @application.group_instances_with_overrides.detect{ |i| i.instance == instance.group_instance }

    if scales_to and scales_from.nil? and scales_to >= 1 and scales_to < override.min_gears
      return render_error(:unprocessable_entity, "The scales_to factor currently provided cannot be lower than the scales_from factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "scales_to")
    end

    if scales_from and scales_to.nil? and override.max_gears >= 1 and override.max_gears < scales_from
      return render_error(:unprocessable_entity, "The scales_from factor currently provided cannot be higher than the scales_to factor previously provided. Please specify both scales_(from|to) factors together to override.", 168, "scales_from")
    end

    scaling_props = nil
    if scales_from || scales_to
      scaling_props = {}
      if scales_from
        scaling_props['scales_from'] = scales_from
      else
        scaling_props['scales_from'] = override.min_gears
      end
      scaling_props['previous_scales_from'] = override.min_gears
      if scales_to
        scaling_props['scales_to'] = scales_to
      else
        scaling_props['scales_to'] = override.max_gears
      end
      scaling_props['previous_scales_to'] = override.max_gears
      gear_count = instance.gears.count
      scaling_props['previous_scale'] = gear_count
      scaling_props['current_scale'] = scales_from ? [scales_from, gear_count].max : gear_count
    end

    storage_props = nil
    if additional_storage
      storage_props = {}
      storage_props['addtl_storage_gb'] = additional_storage
      storage_props['previous_addtl_storage_gb'] = override.additional_filesystem_gb
    end

    result = @application.update_component_limits(instance, scales_from, scales_to, additional_storage)

    if @application.scalable && (scales_from || scales_to)
      @analytics_tracker.identify(@cloud_user.reload)
    end
    @analytics_tracker.track_event("cartridge_update_scale", nil, @application, scaling_props) if scaling_props
    @analytics_tracker.track_event("cartridge_update_storage", nil, @application, storage_props) if storage_props

    instance = @application.component_instances.find_by(cartridge_name: id)
    cartridge = get_embedded_rest_cartridge(
      @application,
      instance,
      instance.group_instance.all_component_instances,
      @application.group_instances_with_overrides.detect{ |i| i.instance == instance.group_instance }
    )

    render_success(:ok, "cartridge", cartridge, "Updated cartridge #{id} for application #{@application.name} under domain #{@application.domain_namespace}", result)
  end
end
