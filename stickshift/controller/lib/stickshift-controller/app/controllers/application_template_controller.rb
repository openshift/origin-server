class ApplicationTemplateController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def index
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_TEMPLATES", true, "Showing all templates")
    templates = ApplicationTemplate.find_all.map{|t| RestApplicationTemplate.new(t, get_url)}
    @reply = RestReply.new(:ok, "application_templates", templates)
    respond_with @reply, :status => @reply.status
  end
  
  def show
    id_or_tag = params[:id]
    template = ApplicationTemplate.find(id_or_tag)
    unless template.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_TEMPLATE", true, "Showing template for '#{id_or_tag}'")
      @reply = RestReply.new(:ok, "application_template", RestApplicationTemplate.new(template, get_url))
      respond_with @reply, :status => @reply.status
    else
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_TEMPLATES", true, "Showing template for '#{id_or_tag}'")
      templates = ApplicationTemplate.find_all(id_or_tag).map{|t| RestApplicationTemplate.new(t, get_url)}
      @reply = RestReply.new(:ok, "application_templates", templates)
      respond_with @reply, :status => @reply.status
    end
  end
end