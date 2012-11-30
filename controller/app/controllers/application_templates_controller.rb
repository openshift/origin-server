class ApplicationTemplatesController < BaseController
  respond_to :xml, :json
  before_filter :check_version

  def index
    templates = ApplicationTemplate.all.map{|t| RestApplicationTemplate.new(t, get_url, nolinks)}
    render_success(:ok, "application_templates", templates, "LIST_TEMPLATES", "Showing all templates")
  end
  
  def show
    id_or_tag = params[:id]
    templates = ApplicationTemplate.where(_id: id_or_tag) + ApplicationTemplate.where(tag: id_or_tag)
    
    return render_success(:ok, "application_template", RestApplicationTemplate.new(templates.first, get_url, nolinks),
                          "SHOW_TEMPLATE", "Showing template for '#{id_or_tag}'") if templates == 1
    
    templates = templates.map{|t| RestApplicationTemplate.new(t, get_url, nolinks)}
    render_success(:ok, "application_templates", templates, "LIST_TEMPLATES",  "Showing template for '#{id_or_tag}'")
  end
end
