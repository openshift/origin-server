class Region
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  embeds_many :zones, class_name: Zone.name

  validates :name, :presence => true

  index({:name => 1}, {:unique => true})
  create_indexes

  REGION_NAME_REGEX = /\A[A-Za-z0-9]*\z/
  def self.check_name!(name)
    if name.blank? or name !~ REGION_NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(Region, nil, [name])
    end
    name
  end

  def self.create(name)
    unless Rails.configuration.msg_broker[:regions][:enabled]
      raise OpenShift::OOException.new("Region creation disabled by the platform.")
    end
    if Region.where(name: Region.check_name!(name)).exists?
      raise OpenShift::OOException.new("Region by name '#{name}' already exists")
    end
    Region.create!(name: name)
  end

  def delete
    raise OpenShift::OOException.new("Couldn't delete region '#{self.name}' because it still contains zones") unless zones.empty?
    super
  end

  def add_zone(name)
    raise OpenShift::OOException.new("Zone name is required") unless name
    if zones.where(name: Zone.check_name!(name)).exists?
      raise OpenShift::OOException.new("Zone '#{name}' already exists in region '#{self.name}'")
    end
    zone = Zone.new(name: name)
    res = Region.where(:_id => self._id).update({"$push" => {"zones" => zone.serializable_hash_with_timestamp}})
    raise OpenShift::OOException.new("Could not add zone #{name} to region #{self.name}") if res.nil? or !res["updatedExisting"]
    self.reload
  end 

  def remove_zone(name)
    raise OpenShift::OOException.new("Zone name is required") unless name
    unless zones.where(name: Zone.check_name!(name)).exists?
      raise OpenShift::OOException.new("Zone '#{name}' not found in region '#{self.name}'")
    end
    zone = zones.find_by(name: name)
    if zone.has_servers?
      raise OpenShift::OOException.new("Couldn't delete zone '#{name}' because it still contains servers")
    end
    res = Region.where(:_id => self._id).update({"$pull" => {"zones" => zone.serializable_hash}})
    raise OpenShift::OOException.new("Could not remove zone #{name} from region #{self.name}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def self.list(name=nil)
    output = []
    query = {}
    query = {'name' => name} if name
    Region.where(query).each do |region|
      output << region.attributes.pretty_inspect
    end
    raise OpenShift::OOException.new("Region '#{name}' not found") if name and output.empty?
    output.join("\n") 
  end
end
