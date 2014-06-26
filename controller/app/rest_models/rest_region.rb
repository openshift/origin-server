class RestRegion < OpenShift::Model
  attr_accessor :id, :name, :zones, :default

  def initialize(region)
    [:id, :name, :zones].each{ |sym| self.send("#{sym}=", region.send(sym)) }
    self.default = region.name ==  Rails.configuration.openshift[:default_region_name] ? true : false
  end

  def to_xml(options={})
    options[:tag_name] = "region"
    super(options)
  end
end
