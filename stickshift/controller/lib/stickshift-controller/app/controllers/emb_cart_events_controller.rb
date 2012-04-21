class EmbCartEventsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper

  # POST /domain/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]/events
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:cartridge_id]
    event = params[:event]

    application = Application.find(@cloud_user,id)
    if(application.nil?)
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    if application.embedded.nil? or not application.embedded.has_key?(cartridge)
      @reply = RestReply.new( :bad_request)
      message = Message.new(:error, "The application #{id} is not configured with embedded cartridge #{cartridge}.", 129) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status 
      return
    end

    begin
      case event
        when 'start'
          application.start(cartridge)      
        when 'stop'
          application.stop(cartridge)      
        when 'restart'
          application.restart(cartridge)          
        when 'reload'
          application.reload(cartridge)
        else
          @reply = RestReply.new(:bad_request)
          message = Message.new(:error, "Invalid event #{event}.  Valid values are start, stop, restart and reload.", 126)
          @reply.messages.push(message)
          respond_with @reply, :status => @reply.status   
          return
      end
    rescue Exception => e
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      message = Message.new(:error, "Failed to add event #{event} on cartridge #{cartridge} for application #{id} due to:#{e.message}", e.code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user, id)
    app = RestApplication.new(application, get_url)
    @reply = RestReply.new(:ok, "application", app)
    message = Message.new(:info, "Added #{event} on #{cartridge} for application #{id}")
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end
end