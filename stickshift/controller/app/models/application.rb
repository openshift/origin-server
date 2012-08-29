require 'matrix'
class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end

# Class to represent an OpenShift Application
# @!attribute [r] name
#   @return [String] The name of the application
# @!attribute [rw] domain_requires
#   @return [Array[String]] Array of IDs of the applications that this application is dependenct on. 
#     If the parent application is destroyed, this application also needs to be destroyed.
# @!attribute [rw] group_overrides
#   @return [Array[Array[String]]] Array of Array of components that need to be co-located
# @!attribute [r] pending_ops
#   @return [Array[PendingAppOps]] Array of pending operations that need to occur for this {Application}
# @!attribute [r] domain
#   @return [Domain] Domain that this application is part of.
# @!attribute [r] user_ids
#   @return [Array[Moped::BSON::ObjectId]] Array of IDs of users that have access to this application.
# @!attribute [r] aliases
#   @return [Array[String]] Array of DNS aliases registered with this application.
#     @see {Application#add_alias} and {Application#remove_alias}
# @!attribute [rw] component_start_order
#   @return [Array[String]] Normally start order computed based on order specified by each component's manufest. This attribute is used to overrides the start order.
# @!attribute [rw] component_stop_order
#   @return [Array[String]] Normally stop order computed based on order specified by each component's manufest. This attribute is used to overrides the stop order.
# @!attribute [r] connections
#   @return [Array[ConnectionInstance]] Array of connections between components of this application
# @!attribute [r] component_instances
#   @return [Array[ComponentInstance]] Array of components in this application
# @!attribute [r] group_instances
#   @return [Array[GroupInstance]] Array of gear groups in the application
# @!attribute [r] app_ssh_keys
#   @return [Array[ApplicationSshKey]] Array of auto-generated SSH keys used by components of the application to connect to other gears.
# @!attribute [r] usage_records
#   @return [Array[UsageRecord]] Array of usage records used to storage gear and filesystem usage for the application.
class Application
  include Mongoid::Document
  include Mongoid::Timestamps
  APP_NAME_MAX_LENGTH = 32
  MAX_SCALE = -1

  field :name, type: String
  field :domain_requires, type: Array, default: []
  field :group_overrides, type: Array, default: []
  embeds_many :pending_ops, class_name: PendingAppOps.name
  
  belongs_to :domain
  field :user_ids, type: Array, default: []
  field :aliases, type: Array, default: []
  field :component_start_order, type: Array, default: []
  field :component_stop_order, type: Array, default: []
  embeds_many :connections, class_name: ConnectionInstance.name
  embeds_many :component_instances, class_name: ComponentInstance.name
  embeds_many :group_instances, class_name: GroupInstance.name
  embeds_many :app_ssh_keys, class_name: ApplicationSshKey.name
  embeds_many :usage_records, class_name: UsageRecord.name  
  
  validates :name,
    presence: {message: "Application name is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid application name. Name must only contain alphanumeric characters."},
    length:   {maximum: APP_NAME_MAX_LENGTH, minimum: 1, message: "Application name must be a minimum of 1 and maximum of #{APP_NAME_MAX_LENGTH} characters."},
    blacklisted: {message: "Application name is not allowed.  Please choose another."}
  validate :extended_validator

  # Returns a map of field to error code for validation failures.
  def self.validation_map
    {name: 105}
  end
  
  before_destroy do |app|
    raise "Please call destroy_app to delete all gears before deleting this application" if num_gears > 0
  end
  
  # Observer hook for extending the validation of the application in an ActiveRecord::Observer
  # @see http://api.rubyonrails.org/classes/ActiveRecord/Observer.html
  def extended_validator
    notify_observers(:validate_application)
  end
  
  # Register a DNS alias for the application.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to associate with this application
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.
  #
  # == Raises:
  # StickShift::UserException if the alias is already been associated with an application.
  def add_alias(fqdn)
    raise StickShift::UserException.new("Alias #{fqdn} is already registered") if Application.where(aliases: fqdn).count > 0
    aliases.push(fqdn)
    pending_op = PendingAppOps.new(op_type: :add_alias, args: {"fqdn" => fqdn})
    pending_ops.push(pending_op)
    return pending_op
  end
  
  # Removes a DNS alias for the application.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to remove from this application
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.
  def remove_alias(fqdn)
    return unless aliases.include? fqdn
    aliases.delete(fqdn)
    pending_op = PendingAppOps.new(op_type: :remove_alias, args: {"fqdn" => fqdn})
    pending_ops.push(pending_op)
    return pending_op
  end
  
  # Initializes the application
  #
  # == Parameters:
  # features::
  #   List of runtime feature requirements. Each entry in the list can be a cartridge name or a feature supported by one of the profiles within the cartridge.
  #
  # domain::
  #   The Domain that this application is part of.
  #
  # name::
  #   The name of this application.
  def initialize(attrs = nil, options = nil)
    super
    self.app_ssh_keys = []    
    self.usage_records = []
    self.pending_ops = []
    self.save
    begin 
      self.requires=attrs[:features] unless (attrs.nil? or attrs[:features].nil?)
    rescue Exception => e
      self.delete
      raise e
    end
  end
  
  # Adds an additional namespace to the application. This function supports the first step of the update namespace workflow.
  #
  # == Parameters:
  # new_namespace::
  #   The new namespace to add to the application
  #
  # pending_parent_op::
  #   The pending domain operation that this update is part of.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.  
  def update_namespace(new_namespace, pending_parent_op=nil)
    op = PendingAppOps.new(op_type: :add_namespace, args: pending_parent_op.args, parent_op: pending_parent_op)
    pending_ops.push(op)
    op
  end
  
  # Removes an existing namespace to the application. This function supports the second step of the update namespace workflow.
  #
  # == Parameters:
  # old_namespace::
  #   The old namespace to remove from the application
  #
  # pending_parent_op::
  #   The pending domain operation that this update is part of.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.  
  def remove_namespace(old_namespace, pending_parent_op=nil)
    op = PendingAppOps.new(op_type: :remove_namespace, args: pending_parent_op.args, parent_op: pending_parent_op)
    pending_ops.push(op)
    op
  end

  # Adds the given ssh key to the application.
  #
  # == Parameters:
  # user_id::
  #   The ID of the user assoicated with the keys. If the user ID is nil, then the key is assumed to be a system generated key.
  # keys::
  #   Array of keys to add to the application.
  # pending_parent_op::
  #   {PendingDomainOps} object used to track this operation at a domain level.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.  
  def add_ssh_keys(user_id, keys, pending_parent_op)
    return if keys.empty?
    key_attrs = keys.map { |k|
      if user_id.nil?
        k["name"] = "domain-" + k["name"]
      else
        k["name"] = user_id.to_s + "-" + k["name"]
      end
      k
    }
    pending_op = PendingAppOps.new(op_type: :update_configuration, args: {"add_keys_attrs" => key_attrs}, parent_op: pending_parent_op)
    pending_ops.push(pending_op)
    return pending_op
  end
  
  # Updates the given ssh key on the application. It uses the user+key name to identify the key to update.
  #
  # == Parameters:
  # user_id::
  #   The ID of the user assoicated with the keys. Update to system keys is not supported.
  # keys_attrs::
  #   Array of keys attributes to update on the application. The name of the key is used to match existing keys.
  # pending_parent_op::
  #   {PendingDomainOps} object used to track this operation at a domain level.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.
  def update_ssh_keys(user_id, keys_attrs, pending_parent_op=nil)
    return if keys_attrs.empty?    
    keys_attrs = keys_attrs.map { |k|
      k["name"] = user_id.to_s + "-" + k["name"]
      k
    }
    op = PendingAppOps.new(op_type: :update_ssh_keys, args: {"keys" => keys_attrs}, parent_op: pending_parent_op)
    pending_ops.push(op)
    return op
  end
  
  # Removes the given ssh key from the application. If multiple users share the same key, only the specified users key is removed
  # but application access will still be possible.
  #
  # == Parameters:
  # user_id::
  #   The ID of the user assoicated with the keys. Update to system keys is not supported.
  # keys_attrs::
  #   Array of keys attributes to remove from the application. The name of the key is used to match existing keys.
  # pending_parent_op::
  #   {PendingDomainOps} object used to track this operation at a domain level.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progess of the operation.
  def remove_ssh_keys(user_id, keys_attrs, pending_parent_op=nil)
    return if keys.empty?    
    key_attrs = keys_attrs.map { |k|
      if user.nil?
        k["name"] = "domain-" + k["name"]
      else
        k["name"] = user._id.to_s + "-" + k["name"]
      end
      k
    }
    op = PendingAppOps.new(op_type: :update_configuration, args: {"remove_keys_attrs" => key_attrs}, parent_op: pending_parent_op)
    pending_ops.push(op)
    op
  end
  
  def add_env_variables(vars, pending_parent_op=nil)
    op = PendingAppOps.new(op_type: :update_configuration, args: {"add_env_variables" => vars}, parent_op: pending_parent_op)
    pending_ops.push(op)
    op
  end
  
  def remove_env_variables(vars, pending_parent_op=nil)
    op = PendingAppOps.new(op_type: :update_configuration, args: {"remove_env_variables" => vars}, parent_op: pending_parent_op)
    pending_ops.push(op)
    op
  end
  
  # Returns the total number of gears currently used by this application
  def num_gears
    num = 0
    group_instances.each { |g| num += g.gears.count}
    num
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
      self.pending_ops.where(:state.ne => :completed).each do |op|
        case op.op_type
        when :create_group_instance
          features += op[:args]["components"].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq
        when :destroy_group_instance
          ginst = self.group_instances.find(op[:args]["group_instance_id"])
          features -= self.component_instances.find(ginst.component_instances).map {|comp_spec| get_feature(comp_spec.cartridge_name, comp_spec.component_name)}.uniq
        when :add_components
          features += op[:args]["components"].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq       
        when :remove_components
          features -= op[:args]["components"].map {|comp_spec| get_feature(comp_spec["cart"], comp_spec["comp"])}.uniq  
        end
      end
    end
    
    features
  end
  
  # Destroys all gears on the application.
  # @note {#run_jobs} must be called in order to perform the updates
  #
  # == Raises:
  # StickShift::UserException if there are existing operations in progress that will change application structure.  
  def destroy_app
    self.requires = []
    pending_ops.push(PendingAppOps.new(op_type: :delete_app))
  end
  
  # Updates the feature requirements of the application and create tasks to perform the update.
  # @note {#run_jobs} must be called in order to perform the updates
  # 
  # == Parameters:
  # features::
  #   A list of features for the application. Each item of the list can be a cartrige name or feature that the cartridge provides
  # group_overrides::
  #   A list of component grouping overrides to use while creating gears
  #
  # == Raises:
  # StickShift::UserException if there are existing operations in progress that will change application structure.  
  def requires=(features, group_overrides=nil)
    if self.pending_ops.where(:state.ne => :completed, flag_req_change: true).count > 0
      raise StickShift::UserException.new("Cannot change application requirements at the moment. There are pending changes in progress.")
    end
    
    unless group_overrides.nil?
      self.set(:group_overrides, group_overrides)
    end
    update_requirements(features, group_overrides || [])
  end
  
  # Updates the component grouping overrides of the application and create tasks to perform the update.
  # @note {#run_jobs} must be called in order to perform the updates
  # 
  # == Parameters:
  # group_overrides::
  #   A list of component grouping overrides to use while creating gears
  #
  # == Raises:
  # StickShift::UserException if there are existing operations in progress that will change application structure.
  def group_overrides=(group_overrides)
    if self.pending_ops.where(flag_req_change: true).count > 0
      raise StickShift::UserException.new("Cannot change application requirements at the moment. There are pending changes in progress.")
    end
    super
    update_requirements(requires, group_overrides)
  end
  
  # Given a set of feature requirements and component grouping overrides, create tasks to perform the update.
  # @note {#run_jobs} must be called in order to perform the updates
  # 
  # == Parameters:
  # features::
  #   A list of features for the application. Each item of the list can be a cartrige name or feature that the cartridge provides
  # group_overrides::
  #   A list of component grouping overrides to use while creating gears
  def update_requirements(features, group_overrides)
    connections, new_group_instances = elaborate(features, group_overrides)
    current_group_instance = self.group_instances.map { |gi| gi.to_hash }
    changes, moves = compute_diffs(current_group_instance,new_group_instances)
    
    app_dns_ginst_op = nil
    num_gears = 0
    ops = []
    changes.each do |change|
      if change[:from].nil?
        num_gears += change[:to_scale][:min]
        pending_op = PendingAppOps.new(op_type: :create_group_instance, args: {"app_dns" => false, "group_instance_id"=> change[:to], "components"=> change[:added], "scale"=> change[:scale]}, flag_req_change: true)
        ops.push(pending_op)
        
        #identify if app dns should be pointing at this gear group
        if app_dns_ginst_op.nil?
          pending_op.args["components"].each do |comp_spec|
            cart = CartridgeCache.find_cartridge(comp_spec["cart"])
            if (cart.categories.include?("web_proxy") || cart.categories.include?("web_framework"))
              pending_op.args["app_dns"] = true 
              break
            end
          end
          app_dns_ginst_op = pending_op
        end
      end
    end
    
    moves.each do |move|
      ops.push(PendingAppOps.new(op_type: :move_component, args: move, flag_req_change: true))
    end
    
    changes.each do |change|
      unless change[:from].nil?
        if change[:to].nil?
          num_gears -= change[:from_scale][:current]
          ops.push(PendingAppOps.new(op_type: :destroy_group_instance, args: {"group_instance_id"=> change[:from]}, flag_req_change: true))
        else
          scale_change = 0
          if change[:from_scale][:current] < change[:to_scale][:min]
            scale_change += change[:to_scale][:min] - change[:from_scale][:current]
          end
          if((change[:from_scale][:current] > change[:to_scale][:max]) && (change[:to_scale][:max] != -1))
            scale_change -= change[:from_scale][:current] - change[:to_scale][:max]
          end
          num_gears += scale_change
          final_scale = change[:from_scale][:current] + scale_change
          
          ops.push(PendingAppOps.new(op_type: :scale_to, args: {"group_instance_id"=> change[:from], "to_scale"=> final_scale})) unless scale_change == 0
          ops.push(PendingAppOps.new(op_type: :add_components, args: {"group_instance_id"=> change[:from], "components"=> change[:added]}, flag_req_change: true)) if change[:added].length > 0
          ops.push(PendingAppOps.new(op_type: :remove_components, args: {"group_instance_id"=> change[:from], "components"=> change[:removed]}, flag_req_change: true)) if change[:removed].length > 0
        end
      end
    end
    #needs to be set and run after all the gears are in place
    ops.push(PendingAppOps.new(op_type: :set_connections, args: {"connections"=> connections}, flag_req_change: true))
    ops.push(PendingAppOps.new(op_type: :execute_connections))
    
    owner = self.domain.owner
    begin
      until Lock.lock_user(owner)
        sleep 1
      end
      if owner.consumed_gears + num_gears > owner.capabilities["max_gears"]
        raise StickShift::GearLimitReachedException.new("#{owner.login} is currently using #{owner.consumed_gears} out of #{owner.capabilities["max_gears"]} limit and this application requires #{num_gears} additional gears.")
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
  # group_overrides::
  #   A list of group-overrides which specify which components must be placed on the same group. 
  #   Components can be specified as Hash{cart: <cart name> [, comp: <component name>]}
  #
  # == Returns:
  # connections::
  #   An array of connections
  # group instances::
  #   An array of hash values representing a group instances.
  def elaborate(features, group_overrides)
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
              "from_comp_inst" => {"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]},
              "to_comp_inst" =>   {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name},
              "from_connector_name" => cinfo[:connector],
              "to_connector_name" =>   sname,
              "connection_type" =>     stype}
            if stype.starts_with?("FILESYSTEM") or stype.starts_with?("SHMEM")
              group_overrides << [{"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]}, {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name}]
            end
          end
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
      scale = {min:1, max: MAX_SCALE}
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
          scale[:max] = comp.scaling.max if (comp.scaling.max != MAX_SCALE) && (scale[:max] == MAX_SCALE || comp.scaling.max < scale[:max])
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
  #     [ {component_instances: [{cart: <cart name>, comp: <comp name>}...], _id: <uuid>, scale: {min: <min scale>, max: <max scale>, current: <current scale>}}...]
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
      from_scale      = {min: 1, max: 100, current: 0}
      to_scale        = {min: 1, max: 100}      
      
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
  
  # Returns the fully qualified domain name where the application can be accessed
  def fqdn
    "#{self.name}-#{self.domain.namespace}.#{Rails.configuration.ss[:domain_suffix]}"
  end

  # Returns the ssh URL to access the gear hosting the web_proxy component 
  def ssh_uri
    web_proxy_ginst = group_instances.find_by(app_dns: true)
    unless web_proxy_ginst.nil?
      "#{web_proxy_ginst.gears[0]._id}@#{fqdn}"
    else
      ""
    end
  end
  
  # Processes directives returned by component hooks to add/remove domain ssh keys, app ssh keys, env variables, broker keys etc
  # @note {#run_jobs} must be called in order to perform the updates
  # 
  # == Parameters:
  # result_io::
  #   {ResultIO} object with directives from cartridge hooks
  def process_commands(result_io)
    commands = result_io.cart_commands
    add_ssh_keys = []
    remove_ssh_keys = []
    
    domain_keys_to_add = []
    domain_keys_to_rm = []
    
    env_vars_to_add = []
    env_vars_to_rm = []
    
    commands.each do |command_item|
      case command_item[:command]
      when "SYSTEM_SSH_KEY_ADD"
        domain_keys_to_add.push({"name" => self.name, "content" => command_item[:args][0], "type" => "ssh-rsa"})
      when "SYSTEM_SSH_KEY_REMOVE"
        domain_keys_to_rm.push({"name" => self.name})
      when "APP_SSH_KEY_ADD"
        add_ssh_keys << ApplicationSshKey.new(name: "applicaiton-" + command_item[:args][0], type: "ssh-rsa", content: command_item[:args][1], created_at: Time.now)
      when "APP_SSH_KEY_REMOVE"
        begin
          remove_ssh_keys << self.app_ssh_keys.find_by(name: "applicaiton-" + command_item[:args][0])
        rescue Mongoid::Errors::DocumentNotFound
          #ignore
        end
      when "ENV_VAR_ADD"
        env_vars_to_add.push({"key" => command_item[:args][0], "value" => command_item[:args][1]})
      when "ENV_VAR_REMOVE"
        env_vars_to_rm.push({"key" => command_item[:args][0]})
      when "BROKER_KEY_ADD"
        iv, token = StickShift::AuthService.instance.generate_broker_key(self)
        #add_broker_auth_key(iv,token)
        #TODO
      when "BROKER_KEY_REMOVE"
        #remove_broker_auth_key
        #TODO        
      end
    end
    
    if add_ssh_keys.length > 0
      keys_attrs = add_ssh_keys.map{|k| k.attributes.dup}
      pending_op = PendingAppOps.new(op_type: :update_configuration, args: {"add_keys_attrs" => keys_attrs})
      Application.where(_id: self._id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash } , "$pushAll" => { app_ssh_keys: keys_attrs }})
    end
    if remove_ssh_keys.length > 0
      keys_attrs = add_ssh_keys.map{|k| k.attributes.dup}
      pending_op = PendingAppOps.new(op_type: :update_configuration, args: {"remove_keys_attrs" => keys_attrs})
      Application.where(_id: self._id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash } , "$pullAll" => { app_ssh_keys: keys_attrs }})
    end
    pending_ops.push(PendingAppOps.new(op_type: :update_configuration, args: {
      "add_keys_attrs" => domain_keys_to_add.map{|k| k.attributes.dup},
      "remove_keys_attrs" => domain_keys_to_rm.map{|k| k.attributes.dup},
      "add_env_vars" => env_vars_to_add,
      "remove_env_vars" => env_vars_to_rm,
    })) if ((domain_keys_to_add.length + domain_keys_to_rm.length + env_vars_to_add.length + env_vars_to_rm.length) > 0)
    nil
  end
  
  # Acquires an application level lock and runs all pending jobs and stops at the first failure.
  #
  # == Returns:
  # True on success or False if unable to acquire the lock or no pending jobs.
  def run_jobs(result_io=nil)
    result_io = ResultIO.new if result_io.nil?
    
    return true if(self.pending_ops.count == 0)
    if(Lock.lock_application(self))
      begin
        ops = self.pending_ops.where(:state.ne => :completed)
        ops.each do |op|
          op.inc(:retry_count, 1)

          case op.op_type
          when :add_namespace
            #todo
            raise "no impl"
          when :remove_namespace
            #todo
            raise "no impl"            
          when :update_ssh_keys
            #todo
            raise "no impl"
          when :update_configuration
            if op.args["gear_ids"].nil?
              gears = self.group_instances.map{ |gi| gi.gears }.flatten
            else
              ginst = self.group_instances.find(op.args["group_instance_id"])
              gears = ginst.gears.find(op.args["gear_ids"])
            end
            GroupInstance.update_configuration(op.args["add_keys_attrs"], op.args["remove_keys_attrs"], op.args["add_env_vars"], op.args["remove_env_vars"], gears)
          when :update_gear_configuration
            #todo recovery
            raise "no impl"
          when :configure_component_on_gears
            #todo recovery
            raise "no impl"
          when :create_group_instance
            #{group_instance_id: change[:to], components: change[:added], scale: change[:scale]}
            contains_web_proxy = false
                        
            if self.group_instances.where(_id: op.args["group_instance_id"]).count == 0
              component_instances = op.args["components"].map { |comp_spec| 
                ComponentInstance.new(cartridge_name: comp_spec["cart"], 
                  component_name: comp_spec["comp"], 
                  group_instance_id: op.args["group_instance_id"]) 
              }
              self.component_instances.push *component_instances
              ginst = GroupInstance.new(custom_id: Moped::BSON::ObjectId.from_string(op.args["group_instance_id"].to_s), app_dns: op.args["app_dns"])
              self.group_instances.push ginst
              result_io.append ginst.update_scale
            else
              ginst = self.group_instances.find(op.args["group_instance_id"])
              component_instances = self.component_instances.where(group_instance_id: op.args["group_instance_id"])
            end

            component_instances.each do |component_instance|
              result_io.append ginst.add_component(component_instance)
              if result_io.exitcode != 0
                raise StickShift::NodeException.new("Unable to configure component #{component_instance.cartridge_name}::#{component_instance.component_name}", result_io.exitcode, result_io)
              end
            end
          when :destroy_group_instance
            #{"group_instance_id"=>"50342afa6892dfbc10000003"}
            ginst = self.group_instances.find_by(_id: op.args["group_instance_id"])
            result_io.append ginst.destroy_instance
            ginst.destroy
          when :add_components
            #{"group_instance_id"=>"50342afa6892dfbc10000003", "components"=>[{"comp"=>"mysql-server", "cart"=>"mysql-5.1"}]}
            component_instances = []
                        
            op.args["components"].each do |comp_spec|
              component_instance = ComponentInstance.new(cartridge_name: comp_spec["cart"], component_name: comp_spec["comp"], group_instance_id: op.args["group_instance_id"])
              component_instances.push component_instance
            end
            
            begin
              ginst =  self.group_instances.find(op.args["group_instance_id"])
            rescue Mongoid::Errors::DocumentNotFound
              #Should not happen
              Rails.logger.error "Group instance #{op.args["group_instance_id"]} expected in app #{_id} but was missing. Creating it."
              ginst = GroupInstance.new(custom_id: Moped::BSON::ObjectId.from_string(op.args["group_instance_id"].to_s), app_dns: op.args["app_dns"])
              self.group_instances.push ginst
              result_io.append ginst.create
            end

            component_instances.each do |component_instance|
              #only configure the component if it was not already configured in a previoud attempt for this group instance
              if(self.component_instances.where(cartridge_name: component_instance.cartridge_name, component_name: component_instance.component_name, group_instance_id: ginst._id).count == 0)
                result_io.append ginst.add_component(component_instance)
                self.component_instances.push component_instances
                if result_io.exitcode != 0
                  self.component_instances.delete component_instances
                  begin
                    result_io.append ginst.remove_component(component_instance)
                  rescue Exception
                    Rails.logger.debug "Error while removing component #{component_instance.cartridge_name} from app #{_id} after failed installation. Will retry"
                    #Ignore
                  end
                  raise StickShift::NodeException.new("Unable to configure component #{component_instance.cartridge_name}::#{component_instance.component_name}", result_io.exitcode, result_io)
                end
              end
            end
          when :remove_components
            #{"group_instance_id"=>"50342afa6892dfbc10000003", "components"=>[{"comp"=>"mysql-server", "cart"=>"mysql-5.1"}]}
            component_instances = []
                        
            op.args["components"].each do |comp_spec|
              begin
                component_instances.push self.component_instances.find_by(cartridge_name: comp_spec["cart"], group_instance_id: op.args["group_instance_id"], component_name: comp_spec["comp"])
              rescue Mongoid::Errors::DocumentNotFound
                #Could happen on retry attempt if some components were removed succesfully earlier
                Rails.logger.debug "Component instance #{comp_spec.inspect} is expected in #{op.args["group_instance_id"]} of app #{_id} but was missing. Ignoring"
              end
            end
            
            begin
              ginst =  self.group_instances.find(op.args["group_instance_id"])
            rescue Mongoid::Errors::DocumentNotFound
              #Should not happen
              Rails.logger.error "Group instance #{op.args["group_instance_id"]} expected in app #{_id} but was missing."
              raise "Group instance #{op.args["group_instance_id"]} expected in app #{_id} but was missing."
            end
            
            component_instances.each do |component_instance|
              result_io.append ginst.remove_component(component_instance)
              if result_io.exitcode != 0
                raise StickShift::NodeException.new("Unable to configure component #{component_instance.cartridge_name}::#{component_instance.component_name}", result_io.exitcode, result_io)
              else
                self.component_instances.delete component_instance
              end
            end
          when :move_component
            #todo
            raise "no impl"
          when :scale_to
            #{"group_instance_id"=> change[:from], "num_gears"=> scale_change}
            ginst = self.group_instances.find(op.args["group_instance_id"])
            ginst.current_scale = op.args["to_scale"]
            ginst.update_scale
          when :set_connections
            conns = []
            op.args["connections"].each do |conn_info|
              from_comp_inst = self.component_instances.find_by(cartridge_name: conn_info["from_comp_inst"]["cart"], component_name: conn_info["from_comp_inst"]["comp"])
              to_comp_inst = self.component_instances.find_by(cartridge_name: conn_info["to_comp_inst"]["cart"], component_name: conn_info["to_comp_inst"]["comp"])
              conns.push(ConnectionInstance.new(
                from_comp_inst_id: from_comp_inst._id, to_comp_inst_id: to_comp_inst._id, 
                from_connector_name: conn_info["from_connector_name"], to_connector_name: conn_info["to_connector_name"],
                connection_type: conn_info["connection_type"]))
            end
            self.connections = conns
          when :execute_connections
            handle = RemoteJob.create_parallel_job
            
            sub_jobs = []
            self.connections.each do |conn|
              pub_inst = self.component_instances.find(conn.from_comp_inst_id)
              pub_ginst = self.group_instances.find(pub_inst.group_instance_id)
              tag = conn._id.to_s
              
              pub_ginst.gears.each do |gear|
                input_args = [gear.name, self.domain.namespace, gear._id.to_s]
                job = gear.get_execute_connector_job(pub_inst.cartridge_name, conn.from_connector_name, input_args)
                RemoteJob.add_parallel_job(handle, tag, gear, job)
              end
            end
            pub_out = {}            
            RemoteJob.execute_parallel_jobs(handle)
            RemoteJob.get_parallel_run_results(handle) do |tag, gear, output, status|
              if status==0
                pub_out[tag] = [] if pub_out[tag].nil?
                pub_out[tag].push("'#{gear}'='#{output}'")
              end
            end
            
            handle = RemoteJob.create_parallel_job
            self.connections.each do |conn|            
              sub_inst = self.component_instances.find(conn.to_comp_inst_id)
              sub_ginst = self.group_instances.find(sub_inst.group_instance_id)
              tag = ""
              
              unless pub_out[conn._id.to_s].nil?
                input_to_subscriber = Shellwords::shellescape(pub_out[conn._id.to_s].join(' '))

                Rails.logger.debug "Output of publisher - '#{pub_out}'"
                sub_ginst.gears.each do |gear|
                  input_args = [gear.name, self.domain.namespace, gear._id.to_s, input_to_subscriber]
                  job = gear.get_execute_connector_job(sub_inst.cartridge_name, conn.to_connector_name, input_args)
                  RemoteJob.add_parallel_job(handle, tag, gear, job)
                end
              end
            end
            RemoteJob.execute_parallel_jobs(handle)            
          when :add_alias
            begin
              ginst = self.group_instances.find_by(app_dns: true)
              ginst.add_alias(op.args["fqdn"])
            rescue Mongoid::Errors::DocumentNotFound
              #ignore. if the group instance does not exist then there is no need to add aliases. It will pick it up when it is created.
            end
          when :remove_alias
            begin
              ginst = self.group_instances.find_by(app_dns: true)
              ginst.remove_alias(op.args["fqdn"])
            rescue Mongoid::Errors::DocumentNotFound
              #ignore. if the group instance does not exist then there is no need to remove aliases.
            end
          when :delete_app
            self.destroy
          end
          
          op.completed
          self.reload if op.op_type != :delete_app
        end
        return true
      ensure
        Lock.unlock_application(self)
      end
    else
      return false
    end
  end

  # Returns the start/stop order specified in the application descriptor or processes the stat and stop
  # orders for each component and returns the final order (topological sort).
  # 
  # == Returns:
  # start_order::
  #   {ComponentInstance} objects ordered by calculated start order
  # stop_order::
  #   {ComponentInstance} objects ordered by calculated stop order  
  def calculate_component_orders
    start_order = ComponentOrder.new
    stop_order = ComponentOrder.new
    comps = []
    categories = {}
    
    #build a map of [categories, features, cart name] => component_instance
    component_instances.each do |comp_inst|
      cart = CartridgeCache.find_cartridge(comp_inst.cartridge_name)
      prof = cart.get_profile_for_component(comp_inst.component_name)
      
      comps << {cart: cart, prof: prof}
      [[comp_inst.cartridge_name],cart.categories,cart.provides,prof.provides].flatten.each do |cat|
        categories[cat] = [] if categories[cat].nil?
        categories[cat] << comp_inst
      end
      start_order.add_component_order([comp_inst])
      stop_order.add_component_order([comp_inst])
    end
    
    #use the map to build DAG for order calculation
    comps.each do |comp_spec|
      start_order.add_component_order(comp_spec[:prof].start_order.map{|c| categories[c]}.flatten)
      stop_order.add_component_order(comp_spec[:prof].stop_order.map{|c| categories[c]}.flatten)
    end
    
    #calculate start order using tsort
    if self.component_start_order.empty?
      computed_start_order = start_order.tsort
    else
      computed_start_order = self.component_start_order.map{|c| categories[c]}.flatten
    end
    
    #calculate stop order using tsort
    if self.component_stop_order.empty?
      computed_stop_order = stop_order.tsort
    else
      computed_stop_order = self.component_stop_order.map{|c| categories[c]}.flatten
    end
    
    [computed_start_order, computed_stop_order]
  end

  # Retrieves the gear state for all gears within the application.
  #
  # == Returns:
  #  Hash of gear id to gear state mappings
  def get_gear_states
    Gear.get_gear_states(group_instances.map{|g| g.gears}.flatten)
  end

  def to_descriptor
    h = {
      "Name" => self.name,
      "Requires" => self.requires(true)
    }
    
    h["Start-Order"] = @start_order unless @start_order.nil? || @start_order.empty?
    h["Stop-Order"] = @stop_order unless @stop_order.nil? || @stop_order.empty?
    h["Group-Overrides"] = self.group_overrides unless self.group_overrides.empty?
    
    h
  end
end
