class EmbCartEventsController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :cartridge
  before_filter :get_application

  # URL: /application/:application_id/cartridge/:name/events
  #
  # Action: POST
  def create
    cartid = params[:cartridge_id].downcase if params[:cartridge_id].presence
    event = params[:event].downcase if params[:event].presence
    cartridge = CartridgeCache.find_cartridge(cartid, @application).name rescue nil

    return render_error(:not_found, "Cartridge #{cartridge} not embedded within application #{@application.name}", 129) if !@application.requires.include?(cartridge)

    authorize! :change_cartridge_state, @application

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
