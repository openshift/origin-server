class ApplicationsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include RestModelHelper
  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "LIST_APPLICATIONS")
    end

    include_cartridges = (params[:include] == "cartridges")
    apps = domain.applications.map! { |application| get_rest_application(application, include_cartridges) }
    render_success(:ok, "applications", apps, "LIST_APPLICATIONS", "Found #{apps.length} applications for domain '#{domain_id}'")
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "SHOW_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      include_cartridges = (params[:include] == "cartridges")
      
      @application_name = application.name
      @application_uuid = application._id.to_s
      render_success(:ok, "application", get_rest_application(application, include_cartridges), "SHOW_APPLICATION", "Application '#{id}' found")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found", 101, "SHOW_APPLICATION")
    end
  end
  
  # POST /domains/[domain_id]/applications
  def create
    domain_id = params[:domain_id]
    app_name = params[:name]
    features = Array(params[:cartridges] || params[:cartridge])
    template_id = params[:template]
    scalable = params[:scale]
    init_git_url = params[:initial_git_url]
    default_gear_size = params[:gear_profile]
    default_gear_size.downcase! if default_gear_size
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127,"ADD_APPLICATION")
    end
    
    if Application.where(domain: domain, name: app_name).count > 0
      return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "ADD_APPLICATION", "name")
    end

    # TODO
    #return render_error(:unprocessable_entity, "Each application must contain one web cartridge.  None of the specified cartridges #{cartridges.to_sentence} is a web cartridge. Please include one of the following cartridges: #{carts.to_sentence}.",
    #		109, "ADD_APPLICATION", "cartridge")
    #return render_error(:unprocessable_entity, "Each application must contain only one web cartridge.  Please include a single web cartridge from this list: #{carts.to_sentence}.",
    #            109, "ADD_APPLICATION", "cartridge")

    begin
      if template_id.nil?
        application = Application.create_app(app_name, features, domain, default_gear_size, scalable, ResultIO.new, [], init_git_url)
      else
        begin
          template = ApplicationTemplate.find(template_id)
        rescue Mongoid::Errors::DocumentNotFound
          return render_error(:not_found, "Template with ID '#{template_id}' not found", 125, "ADD_APPLICATION", "template")
        end

        descriptor_hash = YAML.load(template.descriptor_yaml)
        descriptor_hash["Name"] = app_name
        application = Application.from_template(domain, descriptor_hash, template.git_url)
      end
      @application_name = application.name
      @application_uuid = application._id.to_s
    rescue OpenShift::UnfulfilledRequirementException => e
      return render_error(:unprocessable_entity, "Unable to create application for #{e.feature}", 109, "ADD_APPLICATION", "cartridge")
    rescue OpenShift::ApplicationValidationException => e
      messages = get_error_messages(e.app)
      return render_error(:unprocessable_entity, nil, nil, "ADD_APPLICATION", nil, nil, messages)
    end
    application.user_agent= request.headers['User-Agent']
    
    current_ip = "TODO" #application.group_instances.first.gears.first.get_public_ip_address
    include_cartridges = (params[:include] == "cartridges")
    
    app = get_rest_application(application, include_cartridges)
    reply = RestReply.new(:created, "application", app)
  
    messages = []
    log_msg = "Application #{application.name} was created."
    messages.push(Message.new(:info, log_msg))
    messages.push(Message.new(:info, "#{current_ip}", 0, "current_ip")) unless !current_ip or current_ip.empty?

    #messages.push(Message.new(:info, app_configure_reply.resultIO.string, 0, :result)) if app_configure_reply
    render_success(:created, "application", app, "ADD_APPLICATION", log_msg, nil, nil, messages)
  end
  
  # DELELTE domains/[domain_id]/applications/[id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:id]    
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      @domain_name = domain.namespace
      log_action(@request_id, @cloud_user._id.to_s, @cloud_user.login, "DELETE_APPLICATION", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DELETE_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      @application_name = application.name
      @application_uuid = application._id.to_s
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application #{id} not found.", 101,"DELETE_APPLICATION")
    end
    
    # create tasks to delete gear groups
    application.destroy_app
    render_success(:no_content, nil, nil, "DELETE_APPLICATION", "Application #{id} is deleted.", true) 
  end
end
