class EstimatesController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # GET /estimates
  def index
    render_success(:ok, "estimates", RestEstimates.new(get_url, nolinks), "LIST_ESTIMATES")
  end

  # GET /estimates/<id>  
  def show
    obj = params[:id]
    descriptor = params[:descriptor]

    begin
      raise OpenShift::EstimatesException.new("Invalid estimate object. Estimats only valid for objects: 'application'") if obj != "application"
      raise OpenShift::EstimatesException.new("Application 'descriptor' NOT specified") if !descriptor
      # Get available framework cartriges
      standalone_carts = Application.get_available_cartridges("standalone")

      # Parse given application descriptor
      descriptor.gsub!('\n', "\n")
      descriptor_hash = YAML.load(descriptor)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_ESTIMATE", false, "Invalid application descriptor") unless descriptor_hash
      raise OpenShift::EstimatesException.new("Invalid application descriptor.") unless descriptor_hash
    
      # Find app framework
      framework = nil
      descriptor_hash['Requires'].each do |cart| 
        if standalone_carts.include?(cart)
          framework = cart
          break
        end
      end if descriptor_hash.has_key?('Requires')
      app_name = descriptor_hash['Name'] || nil

      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_ESTIMATE", false, "Application name or framework not found in the descriptor") if !framework or !app_name
      raise OpenShift::EstimatesException.new("Application name or framework not found in the descriptor.") if !framework or !app_name

      # Elaborate app descriptor
      template = ApplicationTemplate.new
      template.descriptor_yaml = descriptor
      app = Application.new(nil, app_name, nil, nil, framework, template)
      app.elaborate_descriptor

      # Generate output  
      groups = []
      app.group_instance_map.values.uniq.each do |ginst|
        components = []
        ginst.component_instances.each do |cname|
          cinst = app.comp_instance_map[cname]
          next if cinst.parent_cart_name == app.name
          comp = {}
          comp['Name'] = cinst.parent_cart_name
          components.push comp
        end if ginst

        if !components.empty?
          app_gear = RestApplicationEstimate.new(components)
          groups.push(app_gear)
        end
      end if app.group_instance_map

      render_success(:ok, "application_estimates", groups, "SHOW_ESTIMATE")
    rescue OpenShift::EstimatesException => e
      return render_error(:unprocessable_entity, e.message, 130, "SHOW_ESTIMATE")
    rescue Exception => e
      return render_exception(e, "SHOW_ESTIMATE")
    end
  end
end
