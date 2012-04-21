class ApplicationTemplateController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def index
    templates = ApplicationTemplate.find_all.map{|t| RestApplicationTemplate.new(t, get_url)}
    @reply = RestReply.new(:ok, "application_templates", templates)
    respond_with @reply, :status => @reply.status
  end
  
  def show
    id_or_tag = params[:id]
    template = ApplicationTemplate.find(id_or_tag)
    unless template.nil?
      @reply = RestReply.new(:ok, "application_template", RestApplicationTemplate.new(template, get_url))
      respond_with @reply, :status => @reply.status
    else
      templates = ApplicationTemplate.find_all(id_or_tag).map{|t| RestApplicationTemplate.new(t, get_url)}
      @reply = RestReply.new(:ok, "application_templates", templates)
      respond_with @reply, :status => @reply.status
    end
  end
end