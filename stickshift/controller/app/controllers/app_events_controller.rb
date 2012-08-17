class AppEventsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # POST /domains/[domain_id]/applications/[application_id]/events
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    
    event = params[:event]
    server_alias = params[:alias]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "APPLICATION_EVENT") if !domain || !domain.hasAccess?(@cloud_user)

    application = Application.find(@cloud_user,id)
    return render_error(:not_found, "Application '#{id}' not found", 101,
                        "APPLICATION_EVENT") unless application
    return render_error(:unprocessable_entity, "Alias must be specified for adding or removing application alias.", 126,
                        "APPLICATION_EVENT", "event") if ['add-alias', 'remove-alias'].include?(event) && !server_alias
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
          return render_error(:unprocessable_entity, "Invalid application event '#{event}' specified",
                              126, "APPLICATION_EVENT", "event")
        end
    rescue Exception => e
      return render_exception(e, "#{event.sub('-', '_').upcase}_APPLICATION")
    end
    application = Application.find(@cloud_user, id)
    app = RestApplication.new(application, get_url, nolinks)
    @reply = RestReply.new(:ok, "application", app)
    message = Message.new("INFO", msg)
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end
end
