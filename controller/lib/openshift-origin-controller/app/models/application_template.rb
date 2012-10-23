class ApplicationTemplate < OpenShift::UserModel
  attr_accessor :uuid, :display_name, :descriptor_yaml, :git_url, :tags, :gear_cost, :metadata
  primary_key :uuid
  
  def initialize(display_name=nil,descriptor_yaml=nil,git_url=nil,tags=[], gear_cost=0, metadata = {})
    self.display_name, self.descriptor_yaml, self.git_url, self.tags, self.gear_cost, self.metadata =
      display_name, descriptor_yaml, git_url, tags, gear_cost, metadata
      self.uuid = OpenShift::Model.gen_uuid
  end
  
  def self.find(id)
    super(nil,id)
  end
  
  def self.find_all(tag=nil)
    tag = {:tag => tag} unless tag.nil?
    super(nil,tag)
  end
  
  def save
    super(nil)
  end
  
  def delete
    super(nil)
  end
end