require 'matrix'
class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end

class Application
  include Mongoid::Document
  include Mongoid::Timestamps
  APP_NAME_MAX_LENGTH = 32

  field :name, type: String
  field :domain_requires, type: Array, default: []
  field :collapse_singleton_gears, type: Boolean, default: true
  field :group_overrides, type:Array, default: []
  embeds_many :pending_ops, class_name: PendingAppOps.name
  
  belongs_to :domain
  has_and_belongs_to_many :users, class_name: CloudUser.name, inverse_of: nil
  #embeds_many :component_configure_order, class_name: ComponentRef.name
  #embeds_many :component_start_order, class_name: ComponentRef.name
  #embeds_many :component_stop_order, class_name: ComponentRef.name
  embeds_many :connections, class_name: ConnectionInstance.name
  embeds_many :component_instances, class_name: ComponentInstance.name
  embeds_many :group_instances, class_name: GroupInstance.name
  
  validates :name,
    presence: {message: "Application name is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid application name. Name must only contain alphanumeric characters."},
    length:   {maximum: APP_NAME_MAX_LENGTH, minimum: 1, message: "Application name must be a minimum of 1 and maximum of #{APP_NAME_MAX_LENGTH} characters."},
    blacklisted: {message: "Application name is not allowed.  Please choose another."}
  validate :extended_validator

  def self.validation_map
    {name: 105}
  end
  
  def extended_validator
    notify_observers(:validate_application)
  end
  
  def initialize(attrs = nil, options = nil)
    super
    
    requires = attrs[:cartridges] unless attrs.nil? or array[:cartridges].nil?
  end
  
  # Returns the feature requirements of the application
  # 
  # == Parameters:
  # include_pending::
  #   Include the pending changes when calulcating the list of features
  #
  # == Returns:
  #   List of features
  def requires(include_pending=false)
    features = component_instances.map {|ci| get_feature(ci.cartridge_name, ci.component_name)}.uniq
    
    if include_pending
      self.pending_ops.each do |op|
        case op.op_type
        when "create_group_instance"
          features += op[:args][:components].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq
        when "add_components"
          features += op[:args][:components].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq       
        when "remove_components"
          features -= op[:args][:components].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq  
        end
      end
    end
    
    features
  end
  
  # Updates the feature requirements of the application and create tasks to perform the update.
  # @node {#run_jobs} must be called in order to perform the updates
  # 
  # == Parameters:
  # features::
  #   A list of features for the application. Each item of the list can be a cartrige name or feature that the cartridge provides
  def requires=(features)
    if (self.pending_ops.delete_if{ |op| !(op.op_type == "create_group_instance" || op.op_type == "add_components" || 
      op.op_type == "remove_components" || op.op_type == "move_component") }.count > 0)
      raise StickShift::UserException.new("Cannot change application requirements at the moment. There are pending changes in progress.")
    end
    
    connections, new_group_instances = elaborate(features, self.group_overrides, self.collapse_singleton_gears)
    current_group_instance = self.group_instances.map { |gi| gi.to_hash }
    changes, moves = compute_diffs(current_group_instance,new_group_instances)
    
    num_gears = 0
    ops = []
    changes.each do |change|
      if change[:from].nil?
        num_gears += change[:to_scale][:min]
        ops.push(PendingAppOps.new(op_type: "create_group_instance", args: {group_instance_id: change[:to], components: change[:added], scale: change[:scale]}))
      end
    end
    
    moves.each do |move|
      ops.push(PendingAppOps.new(op_type: :move_component, args: move))
    end
    
    changes.each do |change|
      unless change[:from].nil?
        if change[:to].nil?
          num_gears -= change[:from_scale][:current]
          ops.push(PendingAppOps.new(op_type: :destroy_group_instance, args: {group_instance_id: change[:from]}))
        else
          scale_change = 0
          if change[:from_scale][:current] < change[:to_scale][:min]
            scale_change += change[:to_scale][:min] - change[:from_scale][:current]
          end
          if change[:from_scale][:current] > change[:to_scale][:max]
            scale_change -= change[:from_scale][:current] - change[:to_scale][:max]
          end
          num_gears += scale_change
          
          ops.push(PendingAppOps.new(op_type: :scale_down, args: {group_instance_id: change[:from], num_gears: scale_change})) if scale_change < 0
          ops.push(PendingAppOps.new(op_type: :scale_up, args: {group_instance_id: change[:from], num_gears: scale_change})) if scale_change > 0
          ops.push(PendingAppOps.new(op_type: :add_components, args: {group_instance_id: change[:from], components: change[:added]})) if change[:added].length > 0
          ops.push(PendingAppOps.new(op_type: :remove_components, args: {group_instance_id: change[:from], components: change[:removed]})) if change[:removed].length > 0
        end
      end
    end
    #needs to be set and run after all the gears are in place
    ops.push(PendingAppOps.new(op_type: :set_connections, args: {connections: connections}))
    ops.push(PendingAppOps.new(op_type: :execute_connections, args: {}))
    
    owner = self.domain.owner
    begin
      until Lock.lock_user(owner)
        sleep 1
      end
      if owner.consumed_gears + num_gears > owner.capabilities["max_gears"]
        raise StickShift::UserException.new("#{owner.login} is currently using #{owner.consumed_gears} out of #{owner.capabilities["max_gears"]} limit and this application requires #{num_gears} additional gears.")
      end
      owner.consumed_gears += num_gears
      pending_ops.push(*ops)
      owner.save
    ensure
      Lock.unlock_user(owner)
    end
  end

  # Computes the group instances, component instances and connections required to support a given set of features
  #
  # == Parameters:
  # features::
  #   A list of features which can include a mix of cartridge name, and features provided by a cartridge or profile
  # collapse_singleton_gears::
  #   A boolean value which specifies if all singleton components should be placed on the same gear as the web-proxy
  # group_overrides::
  #   A list of group-overrides which specify which components must be placed on the same group. 
  #   Components can be specified as {cart: <cart name> [, comp: <component name>]}
  #
  # == Returns:
  # connections:
  #   An array of connections
  # group instances:
  #   An array of hash values representing a group instances.
  def elaborate(features, group_overrides, collapse_singleton_gears)
    profiles = []
    added_cartridges = []

    #calculate initial list based on user provided dependencies
    features.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      raise StickShift::UserException.new("No cartridge found that provides #{feature}") if cart.nil?
      prof = cart.profile_for_feature(feature)
      added_cartridges << cart
      profiles << {cartridge: cart, profile: prof}
    end

    #solve for transitive dependencies
    until added_cartridges.length == 0 do
      carts_to_process = added_cartridges
      added_cartridges = []
      carts_to_process.each do |cart|
        cart.requires.each do |feature|
          next if profiles.count{|d| d[:cartridge].features.include?(feature)} > 0

          cart = CartridgeCache.find_cartridge(feature)
          raise StickShift::UserException.new("No cartridge found that provides #{feature} (transitive dependency)") if cart.nil?
          prof = cart.profile_for_feature(feature)
          added_cartridges << cart
          profiles << {cartridge: cart, profile: prof}
        end
      end
    end

    #calculate component instances
    component_instances = []
    profiles.each do |data|
      data[:profile].components.each do |component|
        component_instances << {
          cartridge: data[:cartridge],
          component: component
        }
      end
      group_overrides += data[:profile].group_overrides
    end

    #calculate connections
    publishers = {}
    connections = []
    component_instances.each do |ci|
      ci[:component].publishes.each do |connector|
        type = connector.type
        name = connector.name
        publishers[type] = [] if publishers[type].nil?
        publishers[type] << { cartridge: ci[:cartridge].name , component: ci[:component].name, connector: name }
      end
    end

    component_instances.each do |ci|
      ci[:component].subscribes.each do |connector|
        stype = connector.type
        sname = connector.name

        if publishers.has_key? stype
          publishers[stype].each do |cinfo|
            connections << {
              from_comp_inst: {"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]},
              to_comp_inst:   {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name},
              from_connector_name: cinfo[:connector],
              to_connector_name:   sname,
              connection_type:     stype}
            if stype.starts_with?("FILESYSTEM") or stype.starts_with?("SHMEM")
              group_overrides << [{"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]}, {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name}]
            end
          end
        end
      end
    end
    
    #collapse singletons
    if collapse_singleton_gears
      component_instances.each do |comp_spec|
        if comp_spec[:component].is_singleton? && !comp_spec[:cartridge].features.include?("web_proxy")
          group_overrides << [{"cart"=> "web_proxy"},
            {"cart"=>comp_spec[:cartridge].name, "comp"=>comp_spec[:component].name}] 
        end
      end
    end

    #calculate group overrides
    group_overrides.map! do |override_spec|
      processed_spec = []
      override_spec.each do |component_spec|
        component_spec = {"cart" => component_spec} if component_spec.class == String
        if component_spec["comp"].nil?
          feature = component_spec["cart"]
          profiles.each do |prof_spec|
            if prof_spec[:cartridge].features.include?(feature) ||  prof_spec[:cartridge].name == feature
              prof_spec[:profile].components.each do |comp|
                processed_spec << {"cart"=> prof_spec[:cartridge].name, "comp"=> comp.name}
              end
            end
          end
        else
          processed_spec << component_spec
        end
      end
      processed_spec
    end
    
    component_instances.map! do |comp_spec|
      {"comp"=> comp_spec[:component].name, "cart"=> comp_spec[:cartridge].name}
    end
    
    #build group_instances
    group_instances = []
    component_instances.each do |comp_spec|
      #look to see if already accounted for
      next if group_instances.reject{ |g| !g[:component_instances].include?(comp_spec) }.count > 0

      #look for any group_overrides for this component
      grouped_components = group_overrides.reject {|o_spec| !o_spec.include?(comp_spec) }.flatten
      
      #no group overrides, component can sit in its own group
      if grouped_components.length == 0
        group_instances << { component_instances: [comp_spec] , _id: Moped::BSON::ObjectId.new}
      else
        #found group overrides, component must sit with other components. 
        #Will possibly require merging exisitng group_instances
        
        existing_g_insts = []
        grouped_components.each do |g_comp_spec|
          existing_g_insts += group_instances.reject{ |g_inst| !g_inst[:component_instances].include?(g_comp_spec) }
        end
        
        existing_g_inst_components = []
        existing_g_insts.each do |g_comp_spec|
          existing_g_inst_components += g_comp_spec[:component_instances]
        end
              
        existing_g_insts.each {|g_inst| group_instances.delete(g_inst)}
        group_instances  << { component_instances: existing_g_inst_components + [comp_spec] , _id: Moped::BSON::ObjectId.new}
      end
    end
    
    #calculate scale factor
    proc_g_insts = group_instances
    group_instances = []
    proc_g_insts.each do |proc_g_inst|
      scale = {min:1, max:-1}
      #g_inst = {components: [], singletons:[], scale:scale}
      num_singletons = 0
      proc_g_inst[:component_instances].each do |comp_spec|
        comp = CartridgeCache.find_cartridge(comp_spec["cart"]).get_component(comp_spec["comp"])
        if comp.is_singleton?
          #g_inst[:singletons] << comp_spec
          num_singletons+= 1
        else
          #g_inst[:components] << comp_spec
          scale[:min] = comp.scaling.min if comp.scaling.min > scale[:min]
          scale[:max] = comp.scaling.max if (comp.scaling.max != -1) && (scale[:max] == -1 || comp.scaling.max < scale[:max])
        end
      end
      scale[:max] = 1 if proc_g_inst[:component_instances].length == num_singletons
      proc_g_inst[:scale] = scale
      group_instances << proc_g_inst
    end
    
    [connections, group_instances]
  end
  
  # Computes the changes (moves, additions, deletions) required to move from the current set of group instances/components to
  # a new set.
  #
  # == Parameters:
  # current_group_instances::
  #   Group instance list containing information about current group instances. Expected format:
  #     [ {component_instances: [{cart: <cart name>, comp: <comp name}...], _id: <uuid>, scale: {min: <min scale>, max: <max scale>, current: <current scale>}}...]
  # new_group_instances::
  #   New set of group instances as computed by the elaborate function
  #
  # == Returns:
  # changes::
  #   Changes needed to th current_group_instances to make it match the new_group_instances. (Includes all adds/removes)
  # moves::
  #   A list of components which need to move from one group instance to another
  def compute_diffs(current_group_instances, new_group_instances)
    axis_size = current_group_instances.length + new_group_instances.length
    cost_matrix = Matrix.build(axis_size,axis_size){0}
    
    #compute cost of moves
    (0..axis_size-1).each do |from|
      (0..axis_size-1).each do |to|
        gi_from = current_group_instances[from].nil? ? [] : current_group_instances[from][:component_instances]
        gi_to   = new_group_instances[to].nil? ? [] : new_group_instances[to][:component_instances]
        
        move_away = gi_from - gi_to
        move_in   = gi_to - gi_from
        cost_matrix[from,to] = move_away.length + move_in.length
      end
    end
    
    #compute changes
    changes = []
    (0..axis_size-1).each do |from|
      best_to = cost_matrix.row_vectors[from].to_a.index(cost_matrix.row_vectors[from].min)        
      from_id = nil
      from_comp_insts = []
      to_comp_insts   = []
      from_scale      = {min: 1, max: -1, current: 0}
      to_scale        = {min: 1, max: -1}      
      
      unless current_group_instances[from].nil?
        from_comp_insts = current_group_instances[from][:component_instances]
        from_id         = current_group_instances[from][:_id]
        from_scale      = current_group_instances[from][:scale]
      end
      
      unless new_group_instances[best_to].nil?
        to_comp_insts = new_group_instances[best_to][:component_instances]
        to_scale      = new_group_instances[best_to][:scale]        
        to_id         = from_id || new_group_instances[best_to][:_id]
      end

      unless from_comp_insts.empty? and to_comp_insts.empty?
        added = to_comp_insts - from_comp_insts
        removed = from_comp_insts - to_comp_insts
        changes << {from: from_id, to: to_id, added: added, removed: removed, from_scale: from_scale, to_scale: to_scale}
      end
      (0..axis_size-1).each {|i| cost_matrix[i,best_to] = 1000}
    end
    
    moves = []
    changes.each do |c1|
      c1[:removed].each do |comp_spec|
        changes.each do |c2| 
          if c2[:added].include?(comp_spec)
            from_id = c1[:from].nil? ? nil : c1[:from]
            to_id = c2[:to].nil? ? nil : c2[:to]
            moves << {component: comp_spec, from_group_instance_id: from_id, to_group_instance_id: to_id}
            c1[:removed].delete comp_spec
            c2[:added].delete comp_spec
            break
          end
        end
      end
    end
    
    [changes, moves]
  end
  
  # Gets a feature name for the cartridge/component combination
  #
  # == Parameters:
  # cartridge_name::
  #   Name of cartridge
  # component_name::
  #   Name of component
  #
  # == Returns:
  # Feature name provided by the cartridge that includes the component
  def get_feature(cartridge_name,component_name)
    cart = CartridgeCache.find_cartridge cartridge_name
    prof = cart.get_profile_for_component component_name
    (prof.provides.length > 0 && prof.name != cart.default_profile) ? prof.provides.first : cart.provides.first
  end
end
