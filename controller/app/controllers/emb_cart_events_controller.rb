class EmbCartEventsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # POST /domain/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]/events
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:cartridge_id]
    event = params[:event]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "CARTRIDGE_EVENT")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application._id.to_s
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "CARTRIDGE_EVENT")
    end
    return render_error(:bad_request, "Cartridge #{cartridge} not embedded within application #{id}", 129, "CARTRIDGE_EVENT") if !application.requires.include?(cartridge)

    begin
      case event
        when 'start'
          application.start(cartridge)      
        when 'stop'
          application.stop(cartridge)      
        when 'restart'
          application.restart(cartridge)          
        when 'reload'
          application.reload_config(cartridge)
        else
          return render_error(:bad_request, "Invalid event '#{event}' for embedded cartridge #{cartridge} within application '#{id}'", 126, "CARTRIDGE_EVENT")
      end
    rescue Exception => e
      return render_exception(e, "CARTRIDGE_EVENT")
    end
   
    if $requested_api_version == 1.0
      app = RestApplication10.new(application, get_url, nolinks)
    else
      app = RestApplication.new(application, get_url, nolinks)
    end
    render_success(:ok, "application", app, "CARTRIDGE_EVENT", "Added #{event} on #{cartridge} for application #{id}", true) 
  end
end
