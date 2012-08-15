class ApplicationTemplatesController < BaseController
  respond_to :xml, :json
  before_filter :check_version
  include LegacyBrokerHelper

  def index
    user_info = get_cloud_user_info(@cloud_user)
    log_action(@request_id, user_info[:uuid], user_info[:login], "LIST_TEMPLATES", true, "Showing all templates")
    templates = ApplicationTemplate.find_all.map{|t| RestApplicationTemplate.new(t, get_url, nolinks)}
    @reply = RestReply.new(:ok, "application_templates", templates)
    respond_with @reply, :status => @reply.status
  end
  
  def show
    id_or_tag = params[:id]
    template = ApplicationTemplate.find(id_or_tag)
    user_info = get_cloud_user_info(@cloud_user)
    unless template.nil?
      log_action(@request_id, user_info[:uuid], user_info[:login], "SHOW_TEMPLATE", true, "Showing template for '#{id_or_tag}'")
      @reply = RestReply.new(:ok, "application_template", RestApplicationTemplate.new(template, get_url, nolinks))
      respond_with @reply, :status => @reply.status
    else
      log_action(@request_id, user_info[:uuid], user_info[:login], "LIST_TEMPLATES", true, "Showing template for '#{id_or_tag}'")
      templates = ApplicationTemplate.find_all(id_or_tag).map{|t| RestApplicationTemplate.new(t, get_url, nolinks)}
      @reply = RestReply.new(:ok, "application_templates", templates)
      respond_with @reply, :status => @reply.status
    end
  end
end
