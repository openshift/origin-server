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
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    if ['add-alias', 'remove-alias'].include?(event) && server_alias.nil?
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "Alias must be specified for adding or removing application alias.", 126, "event")
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status   
      return
    end
    begin
      case event
        when "start"
          application.start
        when "stop"
          application.stop
        when "force-stop"
          application.force_stop
        when "restart"
          application.restart
        when "expose-port"
          application.expose_port
        when "conceal-port"
          application.conceal_port
        when "show-port"
          application.show_port
        when "add-alias"
          application.add_alias(server_alias)
        when "remove-alias"
          application.remove_alias(server_alias)
        when "scale-up"
          application.scaleup
#          if application.web_cart=="jbossas-7"
#            Rails.logger.debug "Restarting JBoss cluster"
#            application.restart
#          end
        when "scale-down"
          application.scaledown
#          if application.web_cart=="jbossas-7"
#            Rails.logger.debug "Restarting JBoss cluster"
#            application.restart
#          end
        else
          @reply = RestReply.new(:unprocessable_entity)
          message = Message.new(:error, "Invalid event #{event}.  Valid events are start, stop, restart, force-stop, expose-port, conceal-port, show-port, scale-up, scale-down, add-alias, remove-alias", 126, "event")
          @reply.messages.push(message)
          respond_with @reply, :status => @reply.status   
          return
        end
    rescue Exception => e
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      message = Message.new(:error, "Failed to add event #{event} to application #{id} due to: #{e.message}", e.code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user, id)
    app = RestApplication.new(application, get_url)
    @reply = RestReply.new(:ok, "application", app)
    message = Message.new("INFO", "Added #{event} to application #{id}")
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end
  
end