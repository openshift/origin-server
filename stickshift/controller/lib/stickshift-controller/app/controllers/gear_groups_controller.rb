class GearGroupsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    
    app = Application.find(@cloud_user,app_id)
    
    if app.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_GEAR_GROUPS", false, "Application '#{app_id}' for domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      gear_states = app.show_state()
      group_instances = app.group_instances.map{ |group_inst| RestGearGroup.new(group_inst, gear_states)}
      @reply = RestReply.new(:ok, "gear_groups", group_instances)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_GEAR_GROUPS", true, "Showing gear groups for application '#{app_id}' with domain '#{domain_id}'")
      respond_with @reply, :status => @reply.status
    end
  end
end
