class ApplicationsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "LIST_APPLICATIONS")
    end

    apps = domain.applications.map! { |application| RestApplication.new(application, get_url, nolinks) }
    render_success(:ok, "applications", apps, "LIST_APPLICATIONS", "Found #{apps.length} applications for domain '#{domain_id}'")
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127, "SHOW_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      app = RestApplication.new(application, get_url, nolinks)
      render_success(:ok, "application", app, "SHOW_APPLICATION", "Application '#{id}' found")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found", 101, "SHOW_APPLICATION")
    end
  end
  
  # POST /domains/[domain_id]/applications
  def create
    domain_id = params[:domain_id]
    app_name = params[:name]
    feature = params[:cartridge]
    template_id = params[:template]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{domain_id}' not found", 127,"ADD_APPLICATION")
    end
    
    if Application.where(domain: domain, name: app_name).count > 0
      return render_error(:unprocessable_entity, "The supplied application name '#{app_name}' already exists", 100, "ADD_APPLICATION", "name")
    end

    application = Application.new(name: app_name, features: [feature], domain: domain)
    if application.invalid?
      messages = get_error_messages(application)
      return render_error(:unprocessable_entity, nil, nil, "ADD_APPLICATION", nil, nil, messages)
    end

    if application.run_jobs
      app = RestApplication.new(application, get_url, nolinks)
      reply = RestReply.new( :created, "application", app)
      message = Message.new(:info, "Application #{application.name} was created.")
      render_success(:created, "application", app, "ADD_APPLICATION", nil, nil, nil, [message]) 
    else
      render_success(:accepted, "application", app, "ADD_APPLICATION", "Delayed setup for application #{app_name} under domain #{domain_id}", true, :info)
    end
  end
  
  # DELELTE domains/[domain_id]/applications/[id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:id]    
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      log_action(@request_id, @cloud_user._id.to_s, @cloud_user.login, "DELETE_APPLICATION", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DELETE_APPLICATION")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application #{id} not found.", 101,"DELETE_APPLICATION")
    end
    
    # create tasks to delete gear groups
    application.destroy_app
    
    # execute the tasks
    if application.run_jobs
      application.destroy
      render_success(:no_content, nil, nil, "DELETE_APPLICATION", "Application #{id} is deleted.", true) 
    else
      render_success(:accepted, "application", app, "DELETE_APPLICATION", "Delayed deletion for application #{app_name} under domain #{domain_id}", true, :info)
    end
  end
end