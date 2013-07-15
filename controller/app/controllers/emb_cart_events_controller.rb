class EmbCartEventsController < BaseController
  include RestModelHelper
  before_filter :get_domain, :get_application
  action_log_tag_resource :cartridge

  # POST /domain/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]/events
  def create
    cartid = params[:cartridge_id].downcase if params[:cartridge_id].presence
    event = params[:event].downcase if params[:event].presence
    cartridge = CartridgeCache.find_cartridge(cartid, @application).name rescue nil
    
    return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{@application.name}", 129) if !@application.requires.include?(cartridge)

    begin
      case event
        when 'start'
          result = @application.start(cartridge)      
        when 'stop'
          result = @application.stop(cartridge)      
        when 'restart'
          result = @application.restart(cartridge)          
        when 'reload'
          result = @application.reload_config(cartridge)
        else
          return render_error(:unprocessable_entity, "Invalid event '#{event}' for embedded cartridge #{cartridge} within application '#{@application.name}'", 126)
      end
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue Exception => e
      return render_exception(e)
    end

    app = get_rest_application(@application)
    render_success(:ok, "application", app, "Added #{event} on #{cartridge} for application #{@application.name}", result) 
  end
  
  protected
    def action_log_tag_action
      if event = params[:event].presence
        event.underscore.upcase
      else
        "UNKNOWN_EVENT"
      end
    end
end
