class EmbCartController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper

  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]
    Rails.logger.debug "Getting cartridges for application #{id} under domain #{domain_id}"
    application = Application.find(@cloud_user,id)
    if application.nil?
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    cartridges = Array.new
    unless application.embedded.nil?
      application.embedded.each do |key, value|
        cartridge = RestCartridge.new("embedded", key, application, get_url)
        cartridges.push(cartridge)
      end
    end
    @reply = RestReply.new(:ok, "cartridges", cartridges)
    respond_with @reply, :status => @reply.status
  end
  
  # GET /domains/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    Rails.logger.debug "Getting cartridge #{id} for application #{application_id} under domain #{domain_id}"
    application = Application.find(@cloud_user,application_id)
    if application.nil?
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    
    unless application.embedded.nil?
      application.embedded.each do |key, value|
        if key == id
          cartridge = RestCartridge.new("embedded", key, application, get_url)
          @reply = RestReply.new(:ok, "cartridge", cartridge)
          respond_with @reply, :status => @reply.status
          return
        end
      end
    end
    @reply = RestReply.new(:not_found)
    message = Message.new(:error, "Cartridge #{id} for application #{application_id} not found.", 129)
    @reply.messages.push(message)
    respond_with @reply, :status => @reply.status
  end

  # POST /domains/[domain_id]/applications/[application_id]/cartridges
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]

    name = params[:name]
    if name.nil?
      # :cartridge param is deprecated because it isn't consistent with
      # the rest of the apis which take :name. Leave it here because
      # some tools may still use it
      name = params[:cartridge]
    end
    colocate_with = params[:colocate_with]

    application = Application.find(@cloud_user,id)
    if(application.nil?)
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    begin
      #container = StickShift::ApplicationContainerProxy.find_available(application.server_identity)
      container = StickShift::ApplicationContainerProxy.find_available(nil)
      if not check_cartridge_type(name, container, "embedded")
        @reply = RestReply.new( :bad_request)
        carts = get_cached("cart_list_embedded", :expires_in => 21600.seconds) {
        Application.get_available_cartridges("embedded")}
        message = Message.new(:error, "Invalid cartridge #{cartridge}.  Valid values are (#{carts.join(', ')})",109,"cartridge") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
    rescue StickShift::NodeException => e
      @reply = RestReply.new(:service_unavailable)
      message = Message.new(:error, e.message, e.code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    rescue Exception => e
      @reply = RestReply.new(:internal_server_error)
      message = Message.new(:error, e.message, e.code) 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    cart_create_reply = ""
    begin
      if not colocate_with.nil?
        application.add_group_override(name, colocate_with)
      end
      cart_create_reply = application.add_dependency(name)
    rescue Exception => e
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      if e.class==StickShift::NodeException 
        message = Message.new(:error, "Failed to add #{name} to application #{id} : #{e.message}. Details : \n#{e.resultIO}", e.code)
      elsif e.class==StickShift::UserException
        message = Message.new(:error, "Failed to add #{name} to application #{id} : #{e.message}", e.code)
      else
        message = Message.new(:error, "Failed to add #{name} to application #{id} due to #{e.message}.")
      end
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    application = Application.find(@cloud_user,id)

    unless application.embedded.nil?
      application.embedded.each do |key, value|
        if key == name
          cartridge = RestCartridge.new("embedded", key, application, get_url)
          @reply = RestReply.new(:created, "cartridge", cartridge)
          message = Message.new(:info, "Added #{name} to application #{id}")
          @reply.messages.push(message)
          message = Message.new(:info, cart_create_reply.resultIO.string, 0, :result)
          @reply.messages.push(message)
          message = Message.new(:info, cart_create_reply.appInfoIO.string, 0, :appinfo)
          @reply.messages.push(message)

          respond_with @reply, :status => @reply.status
          return
        end
      end
    end
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:id]
    application = Application.find(@cloud_user,id)
    if(application.nil?)
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    if application.embedded.nil? or not application.embedded.has_key?(cartridge)
      @reply = RestReply.new( :bad_request)
      message = Message.new(:error, "The application #{id} is not configured with embedded cartridge #{cartridge}.", 129) 
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end

    begin
      Rails.logger.debug "Removing #{cartridge} from application #{id}"
      application.remove_dependency(cartridge)
    rescue Exception => e
      Rails.logger.error "Failed to Remove #{cartridge} from application #{id}: #{e.message}"
      @reply = RestReply.new(:internal_server_error)
      message = Message.new(:error, "Failed to remove #{cartridge} from application #{id} due to:#{e.message}", e.code) 
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
      
    application = Application.find(@cloud_user, id)
    app = RestApplication.new(application, get_url)
    @reply = RestReply.new(:ok, "application", app)
    message = Message.new(:info, "Removed #{cartridge} from application #{id}")
    @reply.messages.push(message)
    respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
  end
end
