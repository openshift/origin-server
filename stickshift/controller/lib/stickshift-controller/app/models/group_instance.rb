class GroupInstance < StickShift::UserModel
  attr_accessor :app, :gears, :node_profile, :component_instances, 
    :name, :cart_name, :profile_name, :group_name, :reused_by
  exclude_attributes :app

  def initialize(app, cartname=nil, profname=nil, groupname=nil, path=nil)
    self.app = app
    self.name = path
    self.cart_name = cartname
    self.profile_name = profname
    self.component_instances = []
    self.group_name = groupname
    self.reused_by = []
    self.gears = []
    self.node_profile = app.node_profile
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
    if not ginst.gears.nil?
      self.gears = [] if self.gears.nil?
      @gears += ginst.gears
    end
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
  
  def add_gear(app)
    gear = Gear.new(app, self)
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
    end
    create_result = gear.create
    unless create_result.exitcode == 0
      raise NodeException.new("Unable to create gear on node", "-100", create_result)
    end
    self.gears << gear
    if app.scalable and not self.component_instances.include? "@@app/comp-proxy/cart-haproxy-1.4"
      app.add_dns(gear.name, app.domain.namespace, gear.get_proxy.get_public_hostname)
    end
    app.add_node_settings([gear])
    return [create_result, gear]
  end

  def fulfil_requirements(app)
    result_io = ResultIO.new
    cart = CartridgeCache::find_cartridge(self.cart_name)
    profile = cart.profiles(self.profile_name)
    group = profile.groups(self.group_name)
    deficit = group.scaling.min - self.gears.length
    deficit.times do
      result, new_gear = add_gear(app)
      result_io.append result
    end
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
      new_components << cpath
      self.component_instances << cpath if not self.component_instances.include? cpath
      app.comp_instance_map[cpath] = ci
      app.working_comp_inst_hash[cpath] = ci
      comp_groups = ci.elaborate(app)
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
end
