##
#@api REST
# Application management APIs
class AppEventsController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :application
  EVENT_REGEX = /\A[a-z]+(-[a-z]+)*\z/
  ##
  # API to perform manage an application
  #
  # Action: POST
  # @param [String] event Application event to create. Supported types include
  #   * start: Start all application cartridges
  #   * stop: Stop all application cartridges
  #   * force-stop: For all application cartridges to stop
  #   * restart: Restart all application cartridges
  #   * add-alias: Associate a new DNS alias with the application. Requires *alias* parameter
  #   * remove-alias: Unassociate a DNS alias from the application. Requires *alias* parameter
  #   * scale-up: Trigger a scale-up for the web framework cartridge
  #   * scale-down: Trigger a scale-down for the web framework cartridge
  #   * thread-dump: Retrieve a list of all threads running on all gears of the application
  #   * tidy: Trigger garbage collection and cleanup of logs, git revisions
  #   * reload: Restart all application cartridges
  # @param [String] alias DNS alias for the application. Only applicable to add-alias and remove-alias events
  #
  # @return [RestReply<RestApplication>] Application object on which the event operates and messages returned for the event.
  def create
    event = params[:event].presence
    server_alias = params[:alias].presence
    deployment_id = params[:deployment_id].presence
    cartridge_name = params[:cartridge_name].presence

    return render_error(:unprocessable_entity, "Event can only contain lowercase a-z and '-' characters", 126,
                        "event") if event !~ EVENT_REGEX

    return render_error(:unprocessable_entity, "Alias must be specified for adding or removing application alias.", 126,
                        "alias") if ['add-alias', 'remove-alias'].include?(event) && (server_alias.nil? or server_alias.to_s.empty?)
    return render_error(:unprocessable_entity, "Reached gear limit of #{@cloud_user.max_gears}", 104) if (event == 'scale-up') && (@cloud_user.consumed_gears >= @cloud_user.max_gears)

    return render_error(:unprocessable_entity, "Deployment ID must be provided for activate.", 126,
                        "deployment_id") if event == "activate" && (deployment_id.nil? or deployment_id.to_s.empty?)


    if @application.quarantined && ['scale-up', 'scale-down'].include?(event)
      return render_upgrade_in_progress
    end

    props = {}
    event_name = nil
    msg = "Sent #{event} to application #{@application.name}"

    case event
    when "start"
      authorize! :change_state, @application
      r = @application.start
      msg = "Application #{@application.name} has started"

    when "stop"
      authorize! :change_state, @application
      r = @application.stop
      msg = "Application #{@application.name} has stopped"

    when "force-stop"
      authorize! :change_state, @application
      r = @application.stop(nil, true)
      msg = "Application #{@application.name} has forcefully stopped"

    when "restart"
      authorize! :change_state, @application
      r = @application.restart
      msg = "Application #{@application.name} has restarted"

    when "show-port", "expose-port", "conceal-port"
      return render_error(:gone, "This event (#{event}) is no longer supported.", 112)

    when "add-alias"
      authorize! :create_alias, @application
      r = @application.add_alias(server_alias)
      props['alias'] = server_alias
      event_name = 'alias_add'
      msg = "Application #{@application.name} has added alias"

    when "remove-alias"
      authorize! :destroy_alias, @application
      r = @application.remove_alias(server_alias)
      props['alias'] = server_alias
      event_name = 'alias_remove'
      msg = "Application #{@application.name} has removed alias"

    when "disable-ha"
      authorize! :disable_ha, @application
      r = @application.disable_ha
      @analytics_tracker.identify(@cloud_user.reload)
      msg = "Application #{@application.name} is now not ha"

    when "make-ha"
      authorize! :make_ha, @application
      r = @application.make_ha
      @analytics_tracker.identify(@cloud_user.reload)
      msg = "Application #{@application.name} is now ha"

    when "scale-up", "scale-down"
      authorize! :scale_cartridge, @application
      instance = @application.web_component_instance or
        raise OpenShift::UserException.new("Application #{@application.name} does not have a web cartridge to scale.")

      scale_by = Integer(params[:by]) rescue nil
      scale_to = Integer(params[:to]) rescue nil
      current = instance.gears.count
      value = scale_to ? (scale_to - current) : (scale_by || 1)*(event == 'scale-down' ? -1 : 1)
      final = current + value

      r = @application.scale_by(instance.group_instance_id, value)
      @analytics_tracker.identify(@cloud_user.reload)
      props['scale_by'] = scale_by if scale_by
      props['scales_to'] = scale_to if scale_to
      props['previous_scale'] = current
      props['current_scale'] = final
      msg = "Application #{@application.name} has scaled to #{final}"

    when "thread-dump"
      authorize! :view_code_details, @application
      r = @application.threaddump
      if r.nil?
        msg = ""
      else
        msg = !r.errorIO.string.empty? ? r.errorIO.string.chomp : ''
      end

    when 'tidy'
      authorize! :change_cartridge_state, @application
      r = @application.tidy
      msg = "Application #{@application.name} called tidy"

    when 'reload'
      authorize! :change_cartridge_state, @application
      r = @application.reload_config
      msg = "Application #{@application.name} called reload"

    when 'activate'
      r = @application.activate(deployment_id)
      msg = "Deployment ID #{deployment_id} on application #{@application.name} has been activated"

    else
      return render_error(:unprocessable_entity, "Invalid application event '#{event}' specified",
                          126, "event")
    end

    @application.reload
    app = get_rest_application(@application)

    if !r.errorIO.string.empty?
      return render_error(r.hasUserActionableError ? :unprocessable_entity : :internal_server_error, "Error occurred while processing event '#{event}': #{r.errorIO.string.chomp}",
                          r.exitcode)
    end

    event_name = "app_#{event.gsub(/-/, '_')}" unless event_name
    @analytics_tracker.track_event(event_name, @domain, @application, props)

    render_success(:ok, "application", app, msg, r)
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
