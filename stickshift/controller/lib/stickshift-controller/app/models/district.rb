class District < StickShift::Model
  
  attr_accessor :server_identities, :active_server_identities_size, :uuid, :creation_time, :available_capacity, :available_uids, :max_uid, :max_capacity, :externally_reserved_uids_size, :node_profile, :name
  primary_key :uuid

  def initialize()
  end
  
  def construct(name, node_profile=nil)
    self.uuid = StickShift::Model.gen_uuid
    self.creation_time = DateTime::now().strftime
    self.server_identities = {}
    self.available_capacity = Rails.configuration.gearchanger[:districts][:max_capacity]
    self.available_uids = []
    self.available_uids.fill(0, Rails.configuration.gearchanger[:districts][:max_capacity]) {|i| i+Rails.configuration.gearchanger[:districts][:first_uid]}
    self.max_uid = Rails.configuration.gearchanger[:districts][:max_capacity] + Rails.configuration.gearchanger[:districts][:first_uid] - 1
    self.max_capacity = Rails.configuration.gearchanger[:districts][:max_capacity]
    self.externally_reserved_uids_size = 0
    self.active_server_identities_size = 0
    self.name = name
    self.node_profile = node_profile ? node_profile : "small"
  end
  
  def self.find(uuid)
    hash = StickShift::DataStore.instance.find_district(uuid)
    return nil unless hash
    hash_to_district(hash)
  end
  
  def self.find_by_name(name)
    hash = StickShift::DataStore.instance.find_district_by_name(name)
    return nil unless hash
    hash_to_district(hash)
  end
  
  def self.find_all()
    data = StickShift::DataStore.instance.find_all_districts()
    return [] unless data
    districts = data.map do |hash|
      hash_to_district(hash)
    end
    districts
  end

  def self.find_available(node_profile=nil)
    hash = StickShift::DataStore.instance.find_available_district(node_profile)
    return nil unless hash
    hash_to_district(hash)
  end
  
  def delete()
    if server_identities.empty?
      StickShift::DataStore.instance.delete_district(@uuid)
    else
      raise StickShift::SSException.new("Couldn't destroy district '#{uuid}' because it still contains nodes")
    end
  end
  
  def save()
    StickShift::DataStore.instance.save_district(@uuid, self.attributes)
    @previously_changed = changes
    @changed_attributes.clear
    @new_record = false
    @persisted = true
    @deleted = false
    self
  end
  
  def add_node(server_identity)
    if server_identity
      hash = StickShift::DataStore.instance.find_district_with_node(server_identity)
      unless hash
        unless server_identities.has_key?(server_identity)
          container = StickShift::ApplicationContainerProxy.instance(server_identity)
          begin
            capacity = container.get_capacity
            if capacity == 0
              container_node_profile = container.get_node_profile
              if container_node_profile == node_profile 
                container.set_district(@uuid, true)
                server_identities[server_identity] = {"active" => true}
                StickShift::DataStore.instance.add_district_node(@uuid, server_identity)
              else
                raise StickShift::SSException.new("Node with server identity: #{server_identity} is of node profile '#{container_node_profile}' and needs to be '#{node_profile}' to add to district '#{name}'")  
              end
            else
              raise StickShift::SSException.new("Node with server identity: #{server_identity} already has apps on it")
            end
          rescue StickShift::NodeException => e
            raise StickShift::SSException.new("Node with server identity: #{server_identity} could not be found")
          end
        else
          raise StickShift::SSException.new("Node with server identity: #{server_identity} already belongs to district: #{@uuid}")
        end
      else
        raise StickShift::SSException.new("Node with server identity: #{server_identity} already belongs to another district: #{hash["uuid"]}")
      end
    else
      raise StickShift::UserException.new("server_identity is required")
    end
  end
  
  def remove_node(server_identity)
    if server_identities.has_key?(server_identity)
      unless server_identities[server_identity]["active"]
        container = StickShift::ApplicationContainerProxy.instance(server_identity)
        capacity = container.get_capacity
        if capacity == 0
          if StickShift::DataStore.instance.remove_district_node(@uuid, server_identity)
            container.set_district('NONE', false)
            server_identities.delete(server_identity)
          else
            raise StickShift::SSException.new("Node with server identity: #{server_identity} could not be removed from district: #{@uuid}")
          end
        else
          raise StickShift::SSException.new("Node with server identity: #{server_identity} could not be removed from district: #{@uuid} because it still has apps on it")
        end
      else
        raise StickShift::SSException.new("Node with server identity: #{server_identity} from district: #{@uuid} must be deactivated before it can be removed")
      end
    else
      raise StickShift::SSException.new("Node with server identity: #{server_identity} doesn't belong to district: #{@uuid}")
    end
  end
  
  def deactivate_node(server_identity)
    if server_identities.has_key?(server_identity)
      if server_identities[server_identity]["active"]
        StickShift::DataStore.instance.deactivate_district_node(@uuid, server_identity)
        container = StickShift::ApplicationContainerProxy.instance(server_identity)
        container.set_district(@uuid, false)
        server_identities[server_identity] = {"active" => false}
      else
        raise StickShift::SSException.new("Node with server identity: #{server_identity} is already deactivated")
      end
    else
      raise StickShift::SSException.new("Node with server identity: #{server_identity} doesn't belong to district: #{@uuid}")
    end
  end
  
  def activate_node(server_identity)
    if server_identities.has_key?(server_identity)
      unless server_identities[server_identity]["active"]
        StickShift::DataStore.instance.activate_district_node(@uuid, server_identity)
        container = StickShift::ApplicationContainerProxy.instance(server_identity)
        container.set_district(@uuid, true)
        server_identities[server_identity] = {"active" => true}
      else
        raise StickShift::SSException.new("Node with server identity: #{server_identity} is already active")
      end
    else
      raise StickShift::SSException.new("Node with server identity: #{server_identity} doesn't belong to district: #{@uuid}")
    end
  end
  
  def add_capacity(num_uids)
    if num_uids > 0
      additions = []
      additions.fill(0, num_uids) {|i| i+max_uid+1}
      StickShift::DataStore.instance.add_district_uids(uuid, additions)
      @available_capacity += num_uids
      @max_uid += num_uids
      @max_capacity += num_uids
      @available_uids += additions
    else
      raise StickShift::SSException.new("You must supply a positive number of uids to remove")
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
            raise StickShift::SSException.new("Uid: #{subtractions[pos]} not found in order in available_uids.  Can not continue!")
          end
        end
        pos += 1 if found_first_pos
        break if pos == subtractions.length
      end
      if !found_first_pos
        raise StickShift::SSException.new("Missing uid: #{subtractions[0]} in existing available_uids.  Can not continue!")
      end
      StickShift::DataStore.instance.remove_district_uids(uuid, subtractions)
      @available_capacity -= num_uids
      @max_uid -= num_uids
      @max_capacity -= num_uids
      @available_uids -= subtractions
    else
      raise StickShift::SSException.new("You must supply a positive number of uids to remove")
    end
  end
  
  private
  
  def self.hash_to_district(hash)
    district = self.new 
    hash.each do |k,v|
      district.instance_variable_set("@#{k}", v)
    end
    district.reset_state
    district
  end
end
