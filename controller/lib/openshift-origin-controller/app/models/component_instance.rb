class ComponentInstance < OpenShift::Model
  attr_accessor :state, :parent_cart_name, :parent_cart_profile, :parent_component_name, :parent_cart_group,
                :name, :dependencies, :group_instance_name, :exec_order, :cart_data, :cart_properties, :addtl_fs_gb

  def initialize (cartname=nil, profname=nil, groupname=nil, compname=nil, pathname=nil, gi=nil)
    self.name = pathname
    self.parent_cart_name = cartname
    self.parent_cart_profile = profname
    self.parent_cart_group = groupname
    self.group_instance_name = gi.name unless gi.nil?
    self.parent_component_name = compname
    self.dependencies = []
    self.exec_order = []
    self.cart_data = []
    self.cart_properties = {}
    self.addtl_fs_gb = 0
  end
  
  def process_cart_data(data)
    data.chomp! if data
    self.cart_data.push data
  end

  def process_cart_properties(properties)
    properties.each do |key, value|
      self.cart_properties[key] = value
    end
  end

  def get_component_definition(app)
    if self.parent_cart_name == app.name
      cart = app
    else
      cart = CartridgeCache::find_cartridge(self.parent_cart_name)
    end
    raise Exception.new("Cartridge #{self.parent_cart_name} not found") if cart.nil?
    profile = cart.profiles(self.parent_cart_profile)
    group = profile.groups(self.parent_cart_group)
    comp_name = group.component_refs(self.parent_component_name).component
    comp = profile.components(comp_name)
    return comp,profile,cart
  end

  def elaborate(app)
    comp,profile,cart = get_component_definition(app)

    self.dependencies = []
    
    # cart map has all the sub-cartridges that will get instantiated through this component instance
    cart_map, cart_map_keys = get_cartridges_for_dependencies(comp, cart)

    group_list = cart_map_keys.map { |key| 
      cartprofile = cart_map[key]
      elaborate_cartridge(cartprofile[0], cartprofile[1], app) 
    }.flatten

    self.dependencies.each do |dep|
      cinst = app.comp_instance_map[dep]
      new_conns = ComponentInstance.establish_connections(cinst, self, app)
      new_conns.each { |conn|
        if conn.from_connector.type.match(/^FILESYSTEM/) or conn.from_connector.type.match(/^AFUNIX/)
          self.exec_order << dep if not self.exec_order.include? dep
        end
      }
    end

    ComponentInstance.establish_connections(self, self, app)

    resolve_exec_order(app)

    return group_list
  end

  def resolve_exec_order(app)
    deps = self.dependencies.dup
    self.dependencies.each { |dep| 
      depinst = app.comp_instance_map[dep]
      comp,p,c = depinst.get_component_definition(app)
      if comp.depends_service and !comp.depends_service.empty?
        comp.depends_service.each { |dependent_cart|
          deps.each { |parent_dep| 
            if parent_dep.include? dependent_cart 
              # add parent_dep to exec_order
              self.exec_order << parent_dep if not self.exec_order.include? parent_dep
            end
          }
        }
      end
      self.exec_order << dep if not self.exec_order.include? dep 
    }
  end

  def self.establish_connections(inst1, inst2, app)
    comp1,prof1,cart1 = inst1.get_component_definition(app)
    comp2,prof2,cart2 = inst2.get_component_definition(app)

    new_connections = []
    
    comp1.publishes.each do |pub|
      comp2.subscribes.each do |sub|
        next if not pub.type==sub.type
        ce = ConnectionEndpoint.new(inst1, inst2, pub, sub) 
        app.conn_endpoints_list << ce
        new_connections << ce
      end
    end
    return if inst1==inst2
    comp1.subscribes.each do |sub|
      comp2.publishes.each do |pub|
        next if not pub.type==sub.type
        ce = ConnectionEndpoint.new(inst2, inst1, pub, sub) 
        app.conn_endpoints_list << ce
        new_connections << ce
      end
    end
    new_connections
  end

  def elaborate_cartridge(cart, profile, app)
    group_list = profile.groups.map do |g|
       gpath = self.name + cart.get_name_prefix + g.get_name_prefix
       gi = app.working_group_inst_hash[gpath]
       if gi.nil?
         gi = app.group_instance_map[gpath]
         if gi.nil?
           gi = GroupInstance.new(app, cart.name, profile.name, g.name, gpath) 
         else
           gi.merge(cart.name, profile.name, g.name, gpath)
         end
       else
         gi.merge(cart.name, profile.name, g.name, gpath)
       end
       app.group_instance_map[gpath] = gi
       app.working_group_inst_hash[gpath] = gi
       sub_components = gi.elaborate(profile, g, self.name, app)
       self.dependencies += sub_components
       gi
    end

    # make connection_endpoints out of provided connections
    profile.connections.each do |conn|
      inst1 = ComponentInstance::find_component_in_cart(profile, app, conn.components[0], self.name)
      inst2 = ComponentInstance::find_component_in_cart(profile, app, conn.components[1], self.name)
      ComponentInstance::establish_connections(inst1, inst2, app)
    end
    
    profile.group_overrides.each do |n, v|
      from_cinst = ComponentInstance::find_component_in_cart(profile, app, n, self.name)
      to_cinst = ComponentInstance::find_component_in_cart(profile, app, v, self.name)
      next if from_cinst.nil? or to_cinst.nil?
      app.group_override_map[from_cinst.group_instance_name] = to_cinst.group_instance_name
      app.group_override_map[to_cinst.group_instance_name] = from_cinst.group_instance_name
    end

    return group_list
  end

  def self.find_component_in_cart(profile, app, comp_name, parent_path) 
    # FIXME : comp_name could be a component_name only, feature_name, cartridge_name that 
    #         one of the components depend upon, or a hierarchical name

    comp_name_list = comp_name.split("/")
    comp_name = comp_name_list.first
    rest = comp_name_list[1..-1]

    group_comp_refs = profile.groups.map { |g| g.component_refs }
    comp_refs = group_comp_refs.flatten
    comp_inst = nil
    comp_refs.each { |comp_ref|
      name_prefix = comp_ref.get_name_prefix(profile)
      comp_inst = app.comp_instance_map[parent_path + name_prefix]
      next if comp_inst.nil?
      if name_prefix!=""
        next if comp_ref.name!=comp_name
        return comp_inst if rest.length==0
        comp_name = rest.first
        rest = rest[1..-1]
      end
      comp_inst.dependencies.each { |dep|
        dep_inst = app.comp_instance_map[dep]
        next if dep_inst.parent_cart_name != comp_name
        return dep_inst if rest.length==0
        c, dep_profile, ca = dep_inst.get_component_definition(app)
        found_inst = self.find_component_in_cart(dep_profile, app, rest.join('/'), dep_inst.name)
        return found_inst if not found_inst.nil?
      }
    }

    return comp_inst
  end

  def set_additional_quota(app, fs_gb, inodes=nil)
    changed_gbs = fs_gb - @addtl_fs_gb
    gi = app.group_instance_map[self.group_instance_name]
    gi.update_quota(changed_gbs, inodes)
    @addtl_fs_gb = fs_gb
  end

  def self.collect_exec_order(app, cinst, return_list)
    cinst.exec_order.each do |dep|
      depinst = app.comp_instance_map[dep]
      collect_exec_order(app, depinst, return_list)
      return_list << dep if not return_list.include? dep
    end
  end

  def get_cartridges_for_dependencies(comp, cart)
    # resolve features into cartridges - two features may resolve
    # into one cartridge only, e.g. depends = [db,db-failover] 
    # will resolve into one mysql cartridge being instantiated with (master/slave) profile
    cart_map = {}
    cart_map_keys = []
    depends = comp.depends + cart.requires_feature
    
    depends.each do |feature| 
      cart = CartridgeCache::find_cartridge(feature)
      raise OpenShift::UserException.new("Invalid cartridge specified: #{feature}",1) if cart.nil?
      capability = feature
      capability = nil if feature==cart.name
      profile = cart.find_profile(capability)
      key = cart.name + profile.name
      cart_map_keys << key if not cart_map_keys.include? key
      cart_map[key] = [cart, profile]
    end
    return cart_map, cart_map_keys
  end

end
