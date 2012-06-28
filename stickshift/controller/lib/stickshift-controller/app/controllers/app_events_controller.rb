class AppEventsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper

  # POST /domains/[domain_id]/applications/[application_id]/events
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    event = params[:event]
    server_alias = params[:alias]
    application = Application.find(@cloud_user,id)
    if application.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "APPLICATION_EVENT", false, "Application '#{id}' not found while processing event '#{event}'")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    if ['add-alias', 'remove-alias'].include?(event) && server_alias.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "#{event.sub('-', '_').upcase}_APPLICATION", false, "Alias not specified for application '#{id}'")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "Alias must be specified for adding or removing application alias.", 126, "event")
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status   
      return
    end
    if event == 'scale-up' && (@cloud_user.consumed_gears >= @cloud_user.max_gears)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "#{event.sub('-', '_').upcase}_APPLICATION", false, "Reached gear limit of #{@cloud_user.max_gears}")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
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
          application.force_stop
          msg = "Application #{id} has forcefully stopped"
        when "restart"
          application.restart
          msg = "Application #{id} has restarted"
        when "expose-port"
          application.expose_port
          msg = "Application #{id} has exposed port"
        when "conceal-port"
          application.conceal_port
          msg = "Application #{id} has concealed port"
        when "show-port"
          r = application.show_port
          msg = "Application #{id} called show port"
          msg += ": #{r.resultIO.string.chomp}" if !r.resultIO.string.empty?
        when "add-alias"
          application.add_alias(server_alias)
          msg = "Application #{id} has added alias"
        when "remove-alias"
          application.remove_alias(server_alias)
          msg = "Application #{id} has removed alias"
        when "scale-up"
          application.scaleup
          msg = "Application #{id} has scaled up"
        when "scale-down"
          application.scaledown
          msg = "Application #{id} has scaled down"
        else
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "APPLICATION_EVENT", false, "Invalid application event '#{event}' specified")
          @reply = RestReply.new(:unprocessable_entity)
          message = Message.new(:error, "Invalid event.  Valid events are start, stop, restart, force-stop, expose-port, conceal-port, show-port, scale-up, scale-down, add-alias, remove-alias", 126, "event")
          @reply.messages.push(message)
          respond_with @reply, :status => @reply.status   
          return
        end
    rescue StickShift::UserException => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "#{event.sub('-', '_').upcase}_APPLICATION", false, "Application event '#{event}' failed: #{e.message}")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "Failed to add event #{event} to application #{id} due to: #{e.message}", e.code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    rescue Exception => e
      Rails.logger.error e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "#{event.sub('-', '_').upcase}_APPLICATION", false, "Application event '#{event}' failed: #{e.message}")
      @reply = RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      message = Message.new(:error, "Failed to add event #{event} to application #{id} due to: #{e.message}", error_code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "#{event.sub('-', '_').upcase}_APPLICATION", true, "Application event '#{event}' successful")
        
    application = Application.find(@cloud_user, id)
    app = RestApplication.new(application, get_url)
    @reply = RestReply.new(:ok, "application", app)
    message = Message.new("INFO", msg)
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end
  
end
