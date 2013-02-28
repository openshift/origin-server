##
#@api REST
# Application management APIs
class AppEventsController < BaseController
  ##
  # API to perform manage an application
  # 
  # URL: /domains/:domain_id/applications/:application_id/events
  #
  # Action: POST
  # @param [String] event Appliction event to create. Supported types include
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
    domain_id = params[:domain_id]
    id = params[:application_id]

    event = params[:event]
    server_alias = params[:alias]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127,
                          "APPLICATION_EVENT") if !domain || !domain.hasAccess?(@cloud_user)
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found", 101, "APPLICATION_EVENT")
    end

    return render_error(:unprocessable_entity, "Alias must be specified for adding or removing application alias.", 126,
                        "APPLICATION_EVENT", "event") if ['add-alias', 'remove-alias'].include?(event) && (server_alias.nil? or server_alias.to_s.empty?)
    return render_error(:unprocessable_entity, "Reached gear limit of #{@cloud_user.max_gears}", 104,
                        "APPLICATION_EVENT") if (event == 'scale-up') && (@cloud_user.consumed_gears >= @cloud_user.max_gears)

    msg = "Added #{event} to application #{id}"
    begin
      case event
        when "start"
          application.start
          msg = "Application #{id} has started"
        when "stop"
          application.stop
          msg = "Application #{id} has stopped"
        when "force-stop"
          application.stop(nil, true)
          msg = "Application #{id} has forcefully stopped"
        when "restart"
          application.restart
          msg = "Application #{id} has restarted"
        when "show-port", "expose-port", "conceal-port"
          return render_error(:gone, "This event (#{event}) is no longer supported.", 112, "APPLICATION_EVENT")
        when "add-alias"
          r = application.add_alias(server_alias)
          msg = "Application #{id} has added alias"
          # msg += ": #{r.resultIO.string.chomp}" if !r.resultIO.string.empty?
        when "remove-alias"
          r = application.remove_alias(server_alias)
          msg = "Application #{id} has removed alias"
          # msg += ": #{r.resultIO.string.chomp}" if !r.resultIO.string.empty?
        when "scale-up"
          web_framework_component_instance = application.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
          application.scale_by(web_framework_component_instance.group_instance_id, 1)
          msg = "Application #{id} has scaled up"
        when "scale-down"
          web_framework_component_instance = application.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
          application.scale_by(web_framework_component_instance.group_instance_id, -1)
          msg = "Application #{id} has scaled down"
        when "thread-dump"
          r = application.threaddump
          if r.nil?
            msg = ""
          else
            msg = !r.errorIO.string.empty? ? r.errorIO.string.chomp : r.resultIO.string.chomp
          end
          #TODO: We need to reconsider how we are reporting messages to the client
          message = Message.new(:result, msg, 0)
          app = if requested_api_version == 1.0
              RestApplication10.new(application, domain, get_url, nolinks)
            else
              RestApplication.new(application, domain, get_url, nolinks)
            end
          return render_success(:ok, "application", app, "#{event.sub('-', '_').upcase}_APPLICATION", "Application event '#{event}' successful", true, nil, [message])
        when 'tidy'
          r = application.tidy
          msg = "Application #{id} called tidy"
          # msg += ": #{r.resultIO.string.chomp}" if !r.resultIO.string.empty?
        when 'reload'
          r = application.reload_config
          msg = "Application #{id} called reload"
          # msg += ": #{r.resultIO.string.chomp}" if !r.resultIO.string.empty?
        else
          return render_error(:unprocessable_entity, "Invalid application event '#{event}' specified",
                              126, "APPLICATION_EVENT", "event")
        end
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code, "#{event.sub('-', '_').upcase}_APPLICATION")
    rescue OpenShift::UserException => uex
      return render_error(:unprocessable_entity, uex.message, uex.code, "#{event.sub('-', '_').upcase}_APPLICATION")
    rescue Exception => e
      return render_exception(e, "#{event.sub('-', '_').upcase}_APPLICATION")
    end

    application = Application.find_by(domain: domain, canonical_name: id.downcase)
    app = if requested_api_version == 1.0
        RestApplication10.new(application, domain, get_url, nolinks)
      else
        RestApplication.new(application, domain, get_url, nolinks)
      end
    @reply = new_rest_reply(:ok, "application", app)
    message = Message.new("INFO", msg)
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end
end
