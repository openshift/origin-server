class District
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :uuid, type: String, default: ""
  field :gear_size, type: String
  field :max_capacity, type: Integer
  field :max_uid, type: Integer
  field :available_uids, type: Array, default: []
  field :available_capacity, type: Integer
  field :active_servers_size, type: Integer
  field :platform, type: String
  embeds_many :servers, class_name: Server.name

  index({:name => 1}, {:unique => true})
  index({:uuid => 1}, {:unique => true})
  index({:gear_size => 1})
  create_indexes

  validates :name, presence: true
  validates :gear_size, presence: true

  DISTRICT_NAME_REGEX = /\A[\w\.\-]+\z/
  def self.check_name!(name)
    if name.blank? or name !~ DISTRICT_NAME_REGEX
      raise OpenShift::OOException.new("Invalid district name '#{name}'")
    end
    name
  end

  def self.create_district(name, gear_size=nil, platform="Linux")
    unless Rails.configuration.msg_broker[:districts][:enabled]
      raise OpenShift::OOException.new("District creation disabled by the platform.")
    end
    if District.where(name: District.check_name!(name)).exists?
      raise OpenShift::OOException.new("District by name #{name} already exists")
    end
    dist = District.new(name: name, platform: platform, gear_size: gear_size)
  end

  def self.find_by_name(name)
    return District.where(name: District.check_name!(name))[0]
  end

  def self.find_server(server_identity, district_list=nil)
    server = nil
    if district_list.present?
      districts = district_list
    else
      districts = District.only(:servers)
    end
    districts.each do |district|
      if district.servers.where(:name => server_identity).exists?
        server = district.servers.find_by(name: server_identity)
        break
      end
    end
    server
  end

  # Since the DISTRICT_FIRST_UID in the msg_broker configuration can change after a district
  # is created, provide a way to compute the first_uid for a give district.
  def first_uid()
    max_uid - max_capacity + 1
  end

  def initialize(attrs = nil, options = nil)
    super

    first_uid = Rails.configuration.msg_broker[:districts][:first_uid]
    num_uids = Rails.configuration.msg_broker[:districts][:max_capacity]
    self.available_uids = []
    self.uuid = self._id.to_s if self.uuid=="" or self.uuid.nil?
    self.available_capacity = num_uids
    self.available_uids = (first_uid...first_uid + num_uids).sort_by{rand}
    self.max_uid = first_uid + num_uids - 1
    self.max_capacity = num_uids
    self.active_servers_size = 0
    self.gear_size = Rails.application.config.openshift[:default_gear_size] unless self.gear_size
    save!
  end

  def self.find_available(gear_size=nil)
    gear_size = gear_size ? gear_size : Rails.application.config.openshift[:default_gear_size]
    valid_district = District.where(:available_capacity.gt => 0, :gear_size => gear_size, :active_servers_size.gt => 0).desc(:available_capacity).first
    valid_district
  end

  def self.find_all(gear_size=nil, include_available_uids=true)
    query = nil
    query = {'gear_size' => gear_size} if gear_size
    if include_available_uids
      District.where(query).find_all.to_a
    else
      District.where(query).only(:name, :uuid, :gear_size, :max_capacity, :max_uid, :available_capacity, :active_servers_size, :servers).find_all.to_a
    end
  end

  def delete
    raise OpenShift::OOException.new("Couldn't delete district '#{name}' because it still contains nodes") unless servers.empty?
    super
  end

  def add_node(server_identity, region_name=nil, zone_name=nil)
    raise OpenShift::OOException.new("server_identity is required") unless server_identity
    region_id = nil
    zone_id = nil
    if region_name
      unless Region.where(name: Region.check_name!(region_name)).exists?
        raise OpenShift::OOException.new("Region object not found, you can create new region '#{region_name}' using oo-admin-ctl-region.")
      end
      raise OpenShift::OOException.new("Zone name is required when region name is specified") unless zone_name
      region = Region.find_by(name: region_name)
      unless region.zones.where(name: Zone.check_name!(zone_name)).exists?
        raise OpenShift::OOException.new("Zone object not found, you can add zone '#{zone_name}' to region '#{region_name}' using oo-admin-ctl-region.")
      end
      region_id = region._id
      zone_id = region.zones.find_by(name: zone_name)._id
    elsif zone_name
      raise OpenShift::OOException.new("Region name is required when zone name is specified")
    end

    if District.where({"servers.name" => server_identity}).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} already belongs to another district")
    end
    container = OpenShift::ApplicationContainerProxy.instance(server_identity)
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} already has gears on it") if container.get_capacity > 0
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} is of node profile " \
          "'#{container.get_node_profile}' and needs to be '#{gear_size}' to add to district '#{name}'") if container.get_node_profile != gear_size

    container.set_district("#{uuid}", true, first_uid, max_uid)
    server = Server.new(name: server_identity, active: true, unresponsive: false)
    if region_name
      server.region_name = region_name
      server.region_id = region_id
      server.zone_name = zone_name
      server.zone_id = zone_id
    end
    begin
      res = District.where(:uuid => self.uuid).update({"$push" => {"servers" => server.as_document}, "$inc" => {"active_servers_size" => 1}})
      raise OpenShift::OOException.new("Could not add node #{server_identity}") if res.nil? or !res["updatedExisting"]
    rescue Exception => e
      container.set_district('NONE', false, first_uid, max_uid)
      raise e
    end
    self.reload
  end

  def remove_node(server_identity)
    unless servers.where(name: server_identity).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
    server = servers.find_by(name: server_identity)
    if server.active
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} from district: #{uuid} must be deactivated before it can be removed")
    end
    begin
      if Application.where({"gears.server_identity" => server_identity}).exists?
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} could not be removed from district: #{uuid} " \
                                         "because some apps in mongo are still using it.")
      end
      unless server.unresponsive
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} could not be removed " \
              "from district: #{uuid} because it still has apps on it") if container.get_capacity > 0
        container.set_district('NONE', false, first_uid, max_uid)
      end
    rescue OpenShift::NodeException => ex
      Rails.logger.error ex.backtrace.inspect
      raise OpenShift::OOException.new("Error: #{ex.message}. Node with server identity: #{server_identity} might be unresponsive, run oo-admin-repair --removed-nodes and retry the current operation.")
    end
    res = District.where(:uuid => self.uuid).update({"$pull" => {"servers" => server.as_document}})
    raise OpenShift::OOException.new("Could not remove node #{server_identity}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def reserve_given_uid(uid)
    res = District.where(:uuid => self.uuid, :available_uids => uid).update({"$pull" => {"available_uids" => uid}, "$inc" => {"available_capacity" => -1}})
    raise OpenShift::OOException.new("Could not reserve given uid #{uid}") if res.nil?
    self.reload
    self.available_uids.include? uid
  end

  def deactivate_node(server_identity)
    unless servers.where(name: server_identity).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
    server = servers.find_by(name: server_identity)
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} is already deactivated") unless server.active

    unless server.unresponsive
      container = OpenShift::ApplicationContainerProxy.instance(server_identity)
      container.set_district("#{uuid}", false, first_uid, max_uid)
    end
    res = District.where("_id" => self._id, "servers.name" => server_identity ).update({"$set" => {"servers.$.active" => false}, "$inc" => {"active_servers_size" => -1}})
    raise OpenShift::OOException.new("Could not deactivate node #{server_identity}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def activate_node(server_identity)
    unless servers.where(name: server_identity).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
    server = servers.find_by(name: server_identity)
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} is already active") if server.active
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} is unresponsive") if server.unresponsive

    container = OpenShift::ApplicationContainerProxy.instance(server_identity)
    container.set_district("#{uuid}", true, first_uid, max_uid)
    res = District.where("_id" => self._id, "servers.name" => server_identity).update({"$set" => {"servers.$.active" => true}, "$inc" => {"active_servers_size" => 1}})
    raise OpenShift::OOException.new("Could not activate node #{server_identity}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def self.reserve_uid(uuid, preferred_uid=nil)
    uid = nil
    if preferred_uid
      obj = District.where(:uuid => uuid, :available_capacity.gt => 0, :available_uids => preferred_uid).find_and_modify({"$pull" => {"available_uids" => preferred_uid}, "$inc" => {"available_capacity" => -1}})
      uid = preferred_uid if obj
    else
      obj = District.where(:uuid => uuid, :available_capacity.gt => 0).find_and_modify({"$pop" => {"available_uids" => -1}, "$inc" => {"available_capacity" => -1}})
      uid = obj.available_uids.first if obj
    end
    return uid
  end

  def self.unreserve_uid(uuid, uid)
    District.where(:uuid => uuid, :available_uids.nin => [uid]).update({"$push" => {"available_uids" => uid}, "$inc" => {"available_capacity" => 1}})
  end

  def add_capacity(num_uids)
    raise OpenShift::OOException.new("You must supply a positive number of uids to add") if num_uids <= 0
    # shuffle the additional UIDs and add them atomically
    additions = (max_uid + 1..max_uid + num_uids).sort_by{rand}
    begin
      OpenShift::ApplicationContainerProxy.set_district_uid_limits("#{uuid}", first_uid, max_uid)
    rescue OpenShift::NodeException => e
      raise OpenShift::OOException.new("There was an issue updating district uid limits on the nodes: #{e.message}")
    end
    res = District.where(:uuid => uuid).update({"$pushAll" => {:available_uids => additions}, "$inc" => {:available_capacity => num_uids, :max_capacity => num_uids, :max_uid => num_uids}})
    raise OpenShift::OOException.new("Could not add capacity to district: #{uuid}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def remove_capacity(num_uids)
    raise OpenShift::OOException.new("You must supply a positive number of uids to remove") if num_uids <= 0
    subtractions = []
    subtractions.fill(0, num_uids) {|i| i + max_uid - num_uids + 1}
    # check if the UIDs being removed are available
    if (subtractions & available_uids).length != subtractions.length
      raise OpenShift::OOException.new("Specified number of UIDs not found in order in available_uids. Can not continue!")
    end
    begin
      OpenShift::ApplicationContainerProxy.set_district_uid_limits("#{uuid}", first_uid, max_uid)
    rescue OpenShift::NodeException => e
      raise OpenShift::OOException.new("There was an issue updating district uid limits on the nodes: #{e.message}")
    end
    res = District.where(:uuid => uuid, :available_uids => {"$all" => subtractions}).update({"$pullAll" => {"available_uids" => subtractions}, "$inc" => {:available_capacity => -num_uids, :max_capacity => -num_uids, :max_uid => -num_uids}})
    raise OpenShift::OOException.new("Could not remove capacity from district: #{uuid}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def set_region(server_identity, region_name, zone_name)
    raise OpenShift::OOException.new("server_identity is required") unless server_identity
    raise OpenShift::OOException.new("region_name is required") unless region_name
    raise OpenShift::OOException.new("zone_name is required") unless zone_name
    unless servers.where(name: server_identity).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} not found in district '#{name}'.")
    end
    server = servers.find_by(name: server_identity)
    raise OpenShift::OOException.new("Node with server identity: #{server_identity} has region: #{server.region_name}, zone: #{server.zone_name}, " \
                                     "unset current region/zone and retry the operation.") if server.region_name
    unless Region.where(name: Region.check_name!(region_name)).exists?
      raise OpenShift::OOException.new("Region object not found, you can create new region '#{region_name}' using oo-admin-ctl-region.")
    end
    region = Region.find_by(name: region_name)
    unless region.zones.where(name: Zone.check_name!(zone_name)).exists?
      raise OpenShift::OOException.new("Zone object not found, you can add zone '#{zone_name}' to region '#{region_name}' using oo-admin-ctl-region.")
    end
    zone = region.zones.find_by(name: zone_name)
    res = District.where("_id" => self._id, "servers.name" => server_identity).update({"$set" => {"servers.$.region_name" => region_name, "servers.$.region_id" => region._id, "servers.$.zone_name" => zone_name, "servers.$.zone_id" => zone._id}})
    raise OpenShift::OOException.new("Could not set region for node #{server_identity}") if res.nil? or !res["updatedExisting"]
    self.reload
  end

  def unset_region(server_identity)
    raise OpenShift::OOException.new("server_identity is required") unless server_identity
    unless servers.where(name: server_identity).exists?
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} not found in district '#{name}'.")
    end
    res = District.where("_id" => self._id, "servers.name" => server_identity).update({"$unset" => {"servers.$.region_name" => "", "servers.$.region_id" => "", "servers.$.zone_name" => "", "servers.$.zone_id" => ""}})
    raise OpenShift::OOException.new("Could not unset region for node #{server_identity}") if res.nil? or !res["updatedExisting"]
    self.reload
  end
end
