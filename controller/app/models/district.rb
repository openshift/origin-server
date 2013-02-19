class District
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :uuid, type: String, default: ""
  field :gear_size, type: String
  field :externally_reserved_uids_size, type: Integer
  field :max_capacity, type: Integer
  field :max_uid, type: Integer
  field :available_uids, type: Array, default: []
  field :available_capacity, type: Integer
  field :active_server_identities_size, type: Integer
  field :server_identities, type: Array

  index({:name => 1}, {:unique => true})
  create_indexes
#  attr_accessor :server_identities, :active_server_identities_size, :uuid, :creation_time, :available_capacity, :available_uids, :max_uid, :max_capacity, :externally_reserved_uids_size, :node_profile, :name

  def self.create_district(name, gear_size=nil)
    profile = gear_size ? gear_size : "small"
    if District.where(name: name).count > 0
      raise OpenShift::OOException.new("District by name #{name} already exists")
    end
    dist = District.new(name: name, gear_size: profile)
  end

  def self.find_by_name(name)
    return District.where(name: name)[0]
  end
  
  def initialize(attrs = nil, options = nil)
    super
    self.server_identities = []
    self.uuid = self._id.to_s if self.uuid=="" or self.uuid.nil?
    self.available_capacity = Rails.configuration.msg_broker[:districts][:max_capacity]
    self.available_uids = []
    self.available_uids.fill(0, Rails.configuration.msg_broker[:districts][:max_capacity]) {|i| i+Rails.configuration.msg_broker[:districts][:first_uid]}
    self.max_uid = Rails.configuration.msg_broker[:districts][:max_capacity] + Rails.configuration.msg_broker[:districts][:first_uid] - 1
    self.max_capacity = Rails.configuration.msg_broker[:districts][:max_capacity]
    self.externally_reserved_uids_size = 0
    self.active_server_identities_size = 0
    save!
  end

  def self.find_available(gear_size=nil)
    gear_size = gear_size ? gear_size : 'small'
    valid_district = District.where(:available_capacity.gt => 0, :gear_size => gear_size, :active_server_identities_size.gt => 0).desc(:available_capacity).first
    valid_district
  end
  
  def self.find_all()
    District.where(nil).find_all.to_a
  end

  def delete()
    if not server_identities.empty?
      raise OpenShift::OOException.new("Couldn't destroy district '#{name}' because it still contains nodes")
    end
    super
  end

  def add_node(server_identity)
    if server_identity
      found = District.in("server_identities.name" => [server_identity]).exists?
      unless found
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        begin
          capacity = container.get_capacity
          if capacity == 0 or capacity == 0.0
            container_node_profile = container.get_node_profile
            if container_node_profile == gear_size
              container.set_district("#{uuid}", true)
              self.active_server_identities_size += 1
              self.server_identities << { "name" => server_identity, "active" => true}
              self.save!
            else
              raise OpenShift::OOException.new("Node with server identity: #{server_identity} is of node profile '#{container_node_profile}' and needs to be '#{gear_size}' to add to district '#{name}'")  
            end
          else
            raise OpenShift::OOException.new("Node with server identity: #{server_identity} already has gears on it")
          end
        rescue OpenShift::NodeException => e
          raise OpenShift::OOException.new("Node with server identity: #{server_identity} could not be found")
        end
      else
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} already belongs to another district")
      end
    else
      raise OpenShift::UserException.new("server_identity is required")
    end
  end

  def server_identities_hash
    sih = {}
    server_identities.each { |server_identity_info| sih[server_identity_info["name"]] = { "active" => server_identity_info["active"]} }
    sih
  end
  
  def remove_node(server_identity)
    server_map = server_identities_hash
    if server_map.has_key?(server_identity)
      unless server_map[server_identity]["active"]
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        capacity = container.get_capacity
        if capacity == 0 or capacity == 0.0
          container.set_district('NONE', false)
          server_identities.delete({ "name" => server_identity, "active" => false} )
          if not self.save
            raise OpenShift::OOException.new("Node with server identity: #{server_identity} could not be removed from district: #{uuid}")
          end
        else
          raise OpenShift::OOException.new("Node with server identity: #{server_identity} could not be removed from district: #{uuid} because it still has apps on it")
        end
      else
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} from district: #{uuid} must be deactivated before it can be removed")
      end
    else
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
  end
  
  def reserve_given_uid(uid)
    District.where(:uuid => self.uuid, :available_uids => uid).find_and_modify( {"$pull" => { "available_uids" => uid }, "$inc" => { "available_capacity" => -1 }})
    self.with(consistency: :strong).reload
    self.available_uids.include? uid
  end

  def deactivate_node(server_identity)
    server_map = server_identities_hash
    if server_map.has_key?(server_identity)
      if server_map[server_identity]["active"]
        District.where("_id" => self._id, "server_identities.name" => server_identity ).find_and_modify({ "$set" => { "server_identities.$.active" => false }, "$inc" => { "active_server_identities_size" => -1 } }, new: true)
        self.with(consistency: :strong).reload
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        container.set_district("#{uuid}", false)
      else
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} is already deactivated")
      end
    else
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
  end
  
  def activate_node(server_identity)
    server_map = server_identities_hash
    if server_map.has_key?(server_identity)
      unless server_map[server_identity]["active"]
        District.where("_id" => self._id, "server_identities.name" => server_identity ).find_and_modify({ "$set" => { "server_identities.$.active" => true}, "$inc" => { "active_server_identities_size" => 1 } }, new: true)
        self.with(consistency: :strong).reload
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        container.set_district("#{uuid}", true)
      else
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} is already active")
      end
    else
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
  end

  def self.reserve_uid(uuid)
    obj = District.where(:uuid => uuid, :available_capacity.gt => 0).find_and_modify( {"$pop" => { "available_uids" => -1}, "$inc" => { "available_capacity" => -1 }})
    return obj.available_uids.first if obj
    return nil
  end

  def self.unreserve_uid(uuid, uid)
    District.where(:uuid => uuid, :available_uids.nin => [uid]).find_and_modify({"$push" => { "available_uids" => uid}, "$inc" => { "available_capacity" => 1 }})
  end
  
  def add_capacity(num_uids)
    if num_uids > 0
      additions = []
      additions.fill(0, num_uids) {|i| i+max_uid+1}
      self.available_capacity += num_uids
      self.max_uid += num_uids
      self.max_capacity += num_uids
      self.available_uids += additions
      self.save!
    else
      raise OpenShift::OOException.new("You must supply a positive number of uids to remove")
    end
  end
  
  def remove_capacity(num_uids)
    if num_uids > 0
      subtractions = []
      subtractions.fill(0, num_uids) {|i| i+max_uid-num_uids+1}
      pos = 0
      found_first_pos = false
      available_uids.each do |available_uid|
        if !found_first_pos && available_uid == subtractions[pos]
          found_first_pos = true
        elsif found_first_pos
          unless available_uid == subtractions[pos]
            raise OpenShift::OOException.new("Uid: #{subtractions[pos]} not found in order in available_uids.  Can not continue!")
          end
        end
        pos += 1 if found_first_pos
        break if pos == subtractions.length
      end
      if !found_first_pos
        raise OpenShift::OOException.new("Missing uid: #{subtractions[0]} in existing available_uids.  Can not continue!")
      end
      self.available_capacity -= num_uids
      self.max_uid -= num_uids
      self.max_capacity -= num_uids
      self.available_uids -= subtractions
      self.save!
    else
      raise OpenShift::OOException.new("You must supply a positive number of uids to remove")
    end
  end

  def self.inc_externally_reserved_uids_size(uuid)
    District.where("uuid" => uuid).find_and_modify({ "$inc" => { "externally_reserved_uids_size" => 1} })
  end
  
end
