class GroupInstance < OpenShift::Model
  attr_accessor :uuid, :app, :gears, :node_profile, :component_instances, :supported_min, :supported_max,
    :name, :cart_name, :profile_name, :group_name, :reused_by, :min, :max, :addtl_fs_gb
  primary_key :uuid
  exclude_attributes :app

  include LegacyBrokerHelper
  
  def initialize(app, cartname=nil, profname=nil, groupname=nil, path=nil)
    self.uuid = OpenShift::Model.gen_uuid
    self.app = app
    self.name = path
    self.cart_name = cartname
    self.profile_name = profname
    self.component_instances = []
    self.group_name = groupname
    self.reused_by = []
    self.gears = []
    self.addtl_fs_gb = 0
    self.node_profile = app.node_profile
    self.supported_min = 1
    self.supported_max = -1
    self.min = 1
    self.max = -1
  end
  
  def node_profile
    # node_profile can be nil for older data.  Should migrate everything to have a node_profile 
    # with the next major migration.
    if @node_profile.nil?
      return Application::DEFAULT_NODE_PROFILE
    else
      return @node_profile
    end
  end

  def self.get(app, id)
    app.group_instances.each do |ginst|
      return ginst if ginst.uuid == id
    end if app.group_instances
    return nil
  end

  def merge_inst(ginst)
    reused = [self.name, self.cart_name, self.profile_name, self.group_name]
    self.reused_by << reused
    self.name = ginst.name
    self.cart_name = ginst.cart_name
    self.profile_name = ginst.profile_name
    self.group_name = ginst.group_name
    ginst.component_instances.each { |ci_name|
      cinst = self.app.comp_instance_map[ci_name]
      next if cinst.nil?
      cur_ginst = self.app.group_instance_map[cinst.group_instance_name]
      self.app.group_instance_map[cinst.group_instance_name] = self if ginst==cur_ginst
    }
    self.component_instances = (self.component_instances + ginst.component_instances).uniq unless ginst.component_instances.nil?
    if not ginst.gears.nil? and ginst.gears.length > 0
      self.gears = [] if self.gears.nil?
      @gears += ginst.gears
      if self.gears.length == 0
        self.uuid = ginst.uuid
      else
        # Since two gear groups are being merged and the structure is being changed,
        # we cannot re-use the uuid from either of the two gear groups
        # Also, how do we merge two group instances that have gears in them
        # without deleting the gears that exist in them
      end
    end
    self.supported_min, self.supported_max = GroupInstance::merge_min_max(self.supported_min, self.supported_max, ginst.supported_min, ginst.supported_max)
    self.min, self.max = GroupInstance::merge_min_max(self.min, self.max, ginst.min, ginst.max)
  end

  def merge(cartname, profname, groupname, path, comp_instance_list=nil)
    reused = [self.name, self.cart_name, self.profile_name, self.group_name]
    self.reused_by << reused
    self.name = path
    self.cart_name = cartname
    self.profile_name = profname
    self.group_name = groupname
    self.component_instances = (self.component_instances + comp_instance_list).uniq unless comp_instance_list.nil?
    # component_instances remains a flat collection
  end
  
  def fix_gear_uuid(app, gear)
    #FIXME: backward compat: first gears UUID = app.uuid
    if app.scalable
      # Override/set gear's uuid with app's uuid if its a scalable app w/ the
      # proxy component.
      if self.component_instances.include? "@@app/comp-proxy/cart-haproxy-1.4"
        gear.uuid = app.uuid
        gear.name = app.name
      end
    else
      # For non scalable app's, gear's uuid is the app uuid.
      gear.uuid = app.uuid
      gear.name = app.name
    end
  end

  def add_gear(app)
    gear = Gear.new(app, self)
    fix_gear_uuid(app, gear)

    # create the gear
    create_result = gear.create

    begin
      if app.scalable and not self.component_instances.include? "@@app/comp-proxy/cart-haproxy-1.4"
        app.add_dns(gear.name, app.domain.namespace, gear.get_proxy.get_public_hostname)
      end
    rescue Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.inspect
      # Cleanup 
      gear.destroy
      raise e 
    end

    if @addtl_fs_gb.kind_of?(Integer) or @addtl_fs_gb.kind_of?(Float) and @addtl_fs_gb > 0
      min_storage = get_cached_min_storage_in_gb()
      set_quota(@addtl_fs_gb + min_storage, nil, [gear])
    end

    app.add_node_settings([gear])
    return [create_result, gear]
  end

  def remove_gear(gear, force=false)
    if force
      return gear.force_destroy
    else
      return gear.destroy
    end
  end

  def update_quota(additional_storage, inodes=nil, gear_list=nil)
    set_quota(@addtl_fs_gb+additional_storage+get_cached_min_storage_in_gb, inodes, gear_list)
  end

  def set_quota(storage_in_gb, inodes=nil, gear_list=nil)
    reply = ResultIO.new
    tag = ""
    previous_fs_gb = @addtl_fs_gb
    gear_list = @gears if gear_list.nil?

    handle = RemoteJob.create_parallel_job
    RemoteJob.run_parallel_on_gears(gear_list, handle) { |exec_handle, gear|
      job = gear.gear_quota_job_update(storage_in_gb, inodes)
      RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
    }

    RemoteJob.get_parallel_run_results(handle) { |tag, gear_uuid, output, status|
      if status != 0
        raise OpenShift::NodeException.new("Error setting quota on gear: #{gear_uuid} with status: #{status} and output: #{output}", 143)
      else
        @gears.each { |gi_gear|
          if gi_gear.uuid == gear_uuid
            # :end usage event for previous quota
            unless previous_fs_gb.nil? || previous_fs_gb == 0
              @addtl_fs_gb = previous_fs_gb
              app.track_usage(gi_gear, UsageRecord::EVENTS[:end], UsageRecord::USAGE_TYPES[:addtl_fs_gb])
            end

            # :begin usage event for new quota
            @addtl_fs_gb = storage_in_gb - get_cached_min_storage_in_gb

            app.track_usage(gi_gear, UsageRecord::EVENTS[:begin], UsageRecord::USAGE_TYPES[:addtl_fs_gb]) if @addtl_fs_gb > 0
            break
          end
        }      
      end
    }

    reply
  end
  
  def get_quota
    additional_storage = @addtl_fs_gb.nil? ? 0 : Integer(@addtl_fs_gb)
    return { "additional_gear_storage" => additional_storage, "base_gear_storage" => get_cached_min_storage_in_gb }
  end

  def get_cached_min_storage_in_gb
    return 1 if @gears.nil? or @gears.length == 0

    quota_blocks_str = get_cached(node_profile + "quota_blocks", :expires_in => 1.day) {@gears[0].get_proxy.get_quota_blocks}
    quota_blocks = Integer(quota_blocks_str)
    # calculate the minimum storage in GB - blocks are 1KB each
    min_storage = quota_blocks / 1024 / 1024
    return min_storage
  end

  def fulfil_requirements(app)
    result_io = ResultIO.new
    return result_io if not app.scalable
    deficit = self.min - self.gears.length
    u = CloudUser.find(self.app.user.login)
    if (deficit + u.consumed_gears) > u.max_gears
      raise OpenShift::UserException.new("#{u.login} has a gear limit of #{u.max_gears} and this app requires #{deficit} more gears. Check the 'scales_from' limit of all cartridges of the app?", 104) 
    end
    deficit.times do
      result, new_gear = add_gear(app)
      result_io.append result
    end
    result_io
  end

  def get_unconfigured_gears(comp_inst)
    unconfigured_gears = []
    self.gears.each do |gear|
      unconfigured_gears << gear if not gear.configured_components.include?(comp_inst.name)
    end
    unconfigured_gears
  end

  def gears=(data)
    @gears = [] if @gears.nil?
    data.each do |hash|
      if hash.class == Gear
        @gears.push hash
      else
        gear = Gear.new(@app,self)
        gear.attributes=hash
        @gears.push gear
      end                             
    end                               
  end

  def elaborate(profile, group, parent_comp_path, app)
    group_inst_hash = {}
    new_components = []
    group.component_refs.each { |comp_ref|
      if self.cart_name == app.name
        cpath = parent_comp_path + comp_ref.get_name_prefix(profile)
      else
        cpath = parent_comp_path + "/cart-" + self.cart_name + comp_ref.get_name_prefix(profile)
      end
      old_ci = app.comp_instance_map[cpath]
      ci = ComponentInstance.new(self.cart_name, self.profile_name, self.group_name, comp_ref.name, cpath, self)
      ci.cart_data += old_ci.cart_data unless old_ci.nil?
      ci.addtl_fs_gb = old_ci.addtl_fs_gb unless old_ci.nil?
      ci.process_cart_properties(old_ci.cart_properties) unless old_ci.nil?
      new_components << cpath
      self.component_instances << cpath if not self.component_instances.include? cpath
      app.comp_instance_map[cpath] = ci
      app.working_comp_inst_hash[cpath] = ci
      comp_groups = ci.elaborate(app)
      c_comp,c_prof,c_cart = ci.get_component_definition(app)
      c_group = c_prof.groups(ci.parent_cart_group)
      self.supported_min, self.supported_max = GroupInstance::merge_min_max(self.supported_min, @supported_max, c_group.scaling.min, c_group.scaling.max)
      self.min, self.max = GroupInstance::merge_min_max(self.min, @max, c_group.scaling.min, c_group.scaling.max)
      group_inst_hash[comp_ref.name] = comp_groups
    }
    
    # TODO: For FUTURE : if one wants to optimize by merging the groups
    # then pick group_inst_hash and merge them up
    # e.g. first component needs 4 groups, second one needs 3
    #   then, make the first three groups of first component also contain
    #   the second component and discard the second component's 3 groups
    #    (to remove groups, erase them from app.comp_instance_map for sure)

    # remove any entries in component_instances that are not part of 
    # application's working component instance hash, because that indicates
    # deleted components
    self.component_instances.delete_if { |cpath| app.working_comp_inst_hash[cpath].nil? }
    new_components
  end

  def supported_max
    if app and not app.scalable
      return @supported_min 
    else
      return @supported_max
    end
  end

  def max
    if app and not app.scalable
      return @min 
    else
      return @max
    end
  end

  def self.merge_min_max(min1, max1, min2, max2)
    newmin = min1>min2 ? min1 : min2

    if max1 < max2 
      if max1 >= 0
        newmax = max1
      else
        newmax = max2
      end
    elsif max2 >= 0
      newmax = max2
    else
      newmax = max1
    end

    if newmin > newmax and newmax >= 0
      newmin = newmax  
    end
    return newmin,newmax
  end

end
