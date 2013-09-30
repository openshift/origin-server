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
  field :active_server_identities_size, type: Integer
  field :server_identities, type: Array

  index({:name => 1}, {:unique => true})
  index({:uuid => 1}, {:unique => true})
  index({:gear_size => 1})
  create_indexes

  def self.create_district(name, gear_size=nil)

    profile = gear_size ? gear_size : Rails.application.config.openshift[:default_gear_size]
    if District.where(name: name).count > 0
      raise OpenShift::OOException.new("District by name #{name} already exists")
    end
    dist = District.new(name: name, gear_size: profile)
  end

  def self.find_by_name(name)
    return District.where(name: name)[0]
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
    self.server_identities = []
    self.available_uids = []
    self.uuid = self._id.to_s if self.uuid=="" or self.uuid.nil?
    self.available_capacity = num_uids
    self.available_uids = (first_uid...first_uid + num_uids).sort_by{rand}
    self.max_uid = first_uid + num_uids - 1
    self.max_capacity = num_uids
    self.active_server_identities_size = 0
    save!
  end

  def self.find_available(gear_size=nil)
    gear_size = gear_size ? gear_size : Rails.application.config.openshift[:default_gear_size]
    valid_district = District.where(:available_capacity.gt => 0, :gear_size => gear_size, :active_server_identities_size.gt => 0).desc(:available_capacity).first
    valid_district
  end

  def self.find_all(gear_size=nil, include_available_uids=true)
    query = nil
    if gear_size
      query = {'gear_size' => gear_size}
    end
    if include_available_uids
      District.where(query).find_all.to_a
    else
      District.where(query).only(:name, :uuid, :gear_size, :max_capacity, :max_uid, :available_capacity, :active_server_identities_size, :server_identities).find_all.to_a
    end
  end

  def delete()
    if not server_identities.empty?
      raise OpenShift::OOException.new("Couldn't delete district '#{name}' because it still contains nodes")
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
            if container.get_node_profile == gear_size
              container.set_district("#{uuid}", true, first_uid, max_uid)
              self.active_server_identities_size += 1
              self.server_identities << { "name" => server_identity, "active" => true}
              self.save!
            else
              raise OpenShift::OOException.new("Node with server identity: #{server_identity} is of node profile '#{container.get_node_profile}' and needs to be '#{gear_size}' to add to district '#{name}'")  
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
    server_identities.each { |server_identity_info| sih[server_identity_info["name"]] = { "active" => server_identity_info["active"], "unresponsive" => server_identity_info["unresponsive"]} }
    sih
  end

  def remove_node(server_identity)
    server_map = server_identities_hash
    if server_map.has_key?(server_identity)
      unless server_map[server_identity]["active"]
        server_unresponsive = server_map[server_identity]["unresponsive"]
        unless server_unresponsive
          container = OpenShift::ApplicationContainerProxy.instance(server_identity)
          capacity = container.get_capacity
        end
        if server_unresponsive or capacity == 0 or capacity == 0.0
          container.set_district('NONE', false, first_uid, max_uid) unless server_unresponsive
          server_identities.delete_if { |si| (si["name"] == server_identity) and (si["active"] == false) }
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
    District.where(:uuid => self.uuid, :available_uids => uid).update( {"$pull" => { "available_uids" => uid }, "$inc" => { "available_capacity" => -1 }})
    self.reload
    self.available_uids.include? uid
  end

  def deactivate_node(server_identity)
    server_map = server_identities_hash
    if server_map.has_key?(server_identity)
      if server_map[server_identity]["active"]
        District.where("_id" => self._id, "server_identities.name" => server_identity ).update({ "$set" => { "server_identities.$.active" => false }, "$inc" => { "active_server_identities_size" => -1 } })
        self.reload
        server_unresponsive = server_map[server_identity]["unresponsive"]
        unless server_unresponsive
          container = OpenShift::ApplicationContainerProxy.instance(server_identity)
          container.set_district("#{uuid}", false, first_uid, max_uid)
        end
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
        District.where("_id" => self._id, "server_identities.name" => server_identity ).update({ "$set" => { "server_identities.$.active" => true}, "$inc" => { "active_server_identities_size" => 1 } })
        self.reload
        container = OpenShift::ApplicationContainerProxy.instance(server_identity)
        container.set_district("#{uuid}", true, first_uid, max_uid)
      else
        raise OpenShift::OOException.new("Node with server identity: #{server_identity} is already active")
      end
    else
      raise OpenShift::OOException.new("Node with server identity: #{server_identity} doesn't belong to district: #{uuid}")
    end
  end

  def self.reserve_uid(uuid, preferred_uid=nil)
    uid = nil
    if preferred_uid
      obj = District.where(:uuid => uuid, :available_capacity.gt => 0, :available_uids => preferred_uid).find_and_modify( {"$pull" => { "available_uids" => preferred_uid }, "$inc" => { "available_capacity" => -1 }})
      uid = preferred_uid if obj
    else
      obj = District.where(:uuid => uuid, :available_capacity.gt => 0).find_and_modify( {"$pop" => { "available_uids" => -1}, "$inc" => { "available_capacity" => -1 }})
      uid = obj.available_uids.first if obj
    end
    return uid
  end

  def self.unreserve_uid(uuid, uid)
    District.where(:uuid => uuid, :available_uids.nin => [uid]).update({"$push" => { "available_uids" => uid}, "$inc" => { "available_capacity" => 1 }})
  end

  def add_capacity(num_uids)
    if num_uids > 0
      # shuffle the additional UIDs and add them atomically
      additions = (max_uid + 1..max_uid + num_uids).sort_by{rand}
      update_result = District.where(:uuid => uuid).update({"$pushAll" => { :available_uids => additions}, "$inc" => { :available_capacity => num_uids, :max_capacity => num_uids, :max_uid => num_uids }})

      if update_result.nil? or (not update_result["updatedExisting"])
        raise OpenShift::OOException.new("Could not add capacity to district: #{uuid}")
      end

      self.reload

      begin
        OpenShift::ApplicationContainerProxy.set_district_uid_limits("#{uuid}", first_uid, max_uid)
      rescue OpenShift::NodeException => e
        raise OpenShift::OOException.new("There was an issue updating district uid limits on the nodes: #{e.message}")
      end

      return self
    else
      raise OpenShift::OOException.new("You must supply a positive number of uids to add")
    end
  end

  def remove_capacity(num_uids)
    if num_uids > 0
      subtractions = []
      subtractions.fill(0, num_uids) {|i| i + max_uid - num_uids + 1}

      # check if the UIDs being removed are available
      if (subtractions & available_uids).length == subtractions.length
        update_result = District.where(:uuid => uuid, :available_uids => { "$all" => subtractions }).update({"$pullAll" => { "available_uids" => subtractions}, "$inc" => { :available_capacity => -num_uids, :max_capacity => -num_uids, :max_uid => -num_uids }})
        if update_result.nil? or (not update_result["updatedExisting"])
          raise OpenShift::OOException.new("Could not remove capacity from district: #{uuid}")
        end
      else
        raise OpenShift::OOException.new("Specified number of UIDs not found in order in available_uids.  Can not continue!")
      end

      self.reload

      begin
        OpenShift::ApplicationContainerProxy.set_district_uid_limits("#{uuid}", first_uid, max_uid)
      rescue OpenShift::NodeException => e
        raise OpenShift::OOException.new("There was an issue updating district uid limits on the nodes: #{e.message}")
      end

      return self
    else
      raise OpenShift::OOException.new("You must supply a positive number of uids to remove")
    end
  end
end
