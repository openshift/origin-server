class EmbCartEventsController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :cartridge
  before_filter :get_application
    EVENT_REGEX = /\A[a-z]+(-[a-z]+)*\z/

  def create
    cartid = params[:cartridge_id].downcase if params[:cartridge_id].presence
    event = params[:event].downcase if params[:event].presence

    cartridge = ComponentInstance.check_name!(cartid)
    instance = @application.component_instances.find_by(cartridge_name: cartridge)

    return render_error(:unprocessable_entity, "Event can only contain characters and '-'", 126,
                        "event") if event !~ EVENT_REGEX

    case event
      when 'start'
        authorize! :change_cartridge_state, @application
        result = @application.start(cartridge)
        msg = "Started #{cartridge} on #{@application.name}"

      when 'stop'
        authorize! :change_cartridge_state, @application
        result = @application.stop(cartridge)
        msg = "Stopped #{cartridge} on #{@application.name}"

      when 'restart'
        authorize! :change_cartridge_state, @application
        result = @application.restart(cartridge)
        msg = "Restarted #{cartridge} on #{@application.name}"

      when 'reload'
        authorize! :change_cartridge_state, @application
        result = @application.reload_config(cartridge)
        msg = "Reloaded #{cartridge} on #{@application.name}"

      when "scale-up", "scale-down"
        authorize! :scale_cartridge, @application

        scale_by = Integer(params[:by]) rescue nil
        scale_to = Integer(params[:to]) rescue nil
        current = instance.gears.count
        value = scale_to ? (scale_to - current) : (scale_by || 1)*(event == 'scale-down' ? -1 : 1)
        final = current + value

        result = @application.scale_by(instance.group_instance_id, value)
        msg = "Cartridge #{cartridge} has scaled to #{final}"

        @analytics_tracker.identify(@cloud_user.reload)
      else
        return render_error(:unprocessable_entity, "Invalid event '#{event}' for embedded cartridge #{cartridge} within application '#{@application.name}'", 126)
    end

    @analytics_tracker.track_event("cartridge_#{event.gsub(/-/, '_')}", @domain, @application, {'cartridge' => cartridge})

    app = get_rest_application(@application)
    render_success(:ok, "application", app, msg, result)
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
