class EmbCartEventsController < BaseController
  include RestModelHelper
  before_filter :get_domain, :get_application
  # POST /domain/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]/events
  def create
    cartridge = params[:cartridge_id].downcase if params[:cartridge_id]
    event = params[:event].downcase if params[:event]
    
    return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{@application.name}", 129) if !@application.requires.include?(cartridge)

    begin
      case event
        when 'start'
          @application.start(cartridge)      
        when 'stop'
          @application.stop(cartridge)      
        when 'restart'
          @application.restart(cartridge)          
        when 'reload'
          @application.reload_config(cartridge)
        else
          return render_error(:unprocessable_entity, "Invalid event '#{event}' for embedded cartridge #{cartridge} within application '#{@application.name}'", 126)
      end
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue Exception => e
      return render_exception(e)
    end

    app = get_rest_application(@application)
    render_success(:ok, "application", app, "Added #{event} on #{cartridge} for application #{@application.name}", true) 
  end
  
  def set_log_tag
    event = params[:event]
    if event
      @log_tag = "#{event.sub('-', '_').upcase}_CARTRIDGE"
    else
      @log_tag = "UNKNOWN_EVENT_CARTRIDGE"
    end
      
  end
end
