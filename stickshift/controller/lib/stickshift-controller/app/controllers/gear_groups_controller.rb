class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    
    app = Application.find(@cloud_user,app_id)
    
    if app.nil?
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      group_instances = app.group_instances.map{ |group_inst| RestGearGroup.new(group_inst)}
      @reply = RestReply.new(:ok, "gear_groups", group_instances)
      respond_with @reply, :status => @reply.status
    end
  end
end
