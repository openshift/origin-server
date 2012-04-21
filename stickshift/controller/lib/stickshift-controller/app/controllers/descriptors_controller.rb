class DescriptorsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    
    application = Application.find(@cloud_user,application_id)
    
    if application.nil?
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      @reply = RestReply.new(:ok, "descriptor", application.to_descriptor.to_yaml)
      respond_with @reply, :status => @reply.status
    end
  end
end