class RestApplicationTemplate < OpenShift::Model
  attr_accessor :uuid, :display_name, :descriptor_yaml, :git_url, :tags, :gear_cost, :metadata, :links
  
  def initialize(template, url, nolinks=false)
    @uuid, @display_name, @descriptor_yaml, @git_url, @tags, @gear_cost, @metadata =
     template._id.to_s, template.display_name, template.descriptor_yaml, template.git_url, template.tags,
        template.gear_cost, template.template_metadata
        
    self.links = {
      "GET_TEMPLATE" => Link.new("Get specific template", "GET", URI::join(url, "application_templates/#{@uuid}")),
      "LIST_TEMPLATES" => Link.new("Get specific template", "GET", URI::join(url, "application_templates")),
      "LIST_TEMPLATES_BY_TAG" => Link.new("Get specific template", "GET", URI::join(url, "application_templates/TAG"))
    } unless nolinks
  end
  
  def to_xml(options={})
    options[:tag_name] = "template"
    super(options)
  end
end
