# Represents a group of gears what scale together and have the same components installed.
# @!attribute [r] application
#   @return [Application] that this {GroupInstance} is part of.
# @!attribute [rw] min
#   @return [Integer] Calculated minimum set of gears supported by {ComponentInstance}s in the group.
# @!attribute [rw] max
#   @return [Integer] Calculated maximum set of gears supported by {ComponentInstance}s in the group.
# @!attribute [rw] user_min
#   @return [Integer] User set minimum number of gears.
# @!attribute [rw] user_max
#   @return [Integer] User set maximum number of gears.
# @!attribute [rw] current_scale
#   @return [Integer] The number of gears that this {GroupInstance} should have
# @!attribute [r] gear_profile
#   @return [String] Gear profile of all gears under this {GroupInstance}
# @!attribute [rw] component_instances
#   @return [Array[Moped::BSON::ObjectId]] IDs of non-singleton {ComponentInstance}s that are part of this {GroupInstance}
# @!attribute [rw] singleton_instances
#   @return [Array[Moped::BSON::ObjectId]] IDs of singleton {ComponentInstance}s that are part of this {GroupInstance}
# @!attribute [r] gears
#   @return [Array[Gear]] List of gears that are part of this {GroupInstance}
# @!attribute [r] app_dns
#   @return [Boolean] Indicates if the group instance hosts the web_proxy component and has the Application DNS pointed to it.
class GroupInstance
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  
  field :min, type: Integer, default: 1
  field :max, type: Integer, default: -1
  field :user_min, type: Integer, default: 1
  field :user_max, type: Integer, default: -1
  field :current_scale, type: Integer, default: 1
  
  field :gear_profile, type: String, default: "small"
  field :component_instances, type: Array, default: []
  field :singleton_instances, type: Array, default: []
  embeds_many :gears, class_name: Gear.name
  field :app_dns, type: Boolean, default: false
  
  # Initializes the application
  #
  # == Parameters:
  # custom_id::
  #   Specify a Moped::BSON::ObjectId to identify this instance
  # app_dns::
  #   Specified that this group instance hosts the primary application DNS endpoint.
  #   @Note used when this gear is hosting the web_proxy component
  def initialize(attrs = nil, options = nil)
    super
    self._id = attrs[:custom_id] unless attrs[:custom_id].nil?
  end

  # Creates gears within the group instance to satisfy the min gears scaling requirement. This method will also add application aliases to all gears.
  # Destroys gears within the group instance to satisfy the max gears scaling requirement.
  #
  # Each gear is assigned a gear-specific DNS entry.The first gear is assigned the application DNS entry if this instance hosts the web_proxy component.
  # SSH keys and Environment variables are not added by this method.
  #
  # @note The first gear of the group instance is assigned with the application name and _id if the group_instance hosts the web_proxy component.
  #   This is done for backward compatibility reasons and will be removed once typeless gears transition is completed.
  def update_scale
    result_io = ResultIO.new
    min = self.min < self.user_min ? self.user_min : self.min
    max = self.max
    max = self.user_max if ((self.user_max != -1) && ((self.max == -1) || (self.user_max < self.max)))

    self.current_scale = max if ((current_scale > max) && max != -1)
    self.current_scale = min if (current_scale < min)

    #scale up
    if gears.count < self.current_scale
      new_gears = []
      while(gears.count < self.current_scale) do
        gear = Gear.new
        #TODO: Remove when typeless gears is completed
        if(app_dns && gears.count==0)
          gear._id = application._id.dup
          gear.name = application.name
        else
          gear.name = gear._id.to_s[0..9]
        end
        #END-TODO#
        
        gears.push gear
        new_gears.push gear
        begin
          result_io.append gear.create
          
          #register application DNS entry
          if self.app_dns && gears[0] == gear
            #TODO: Uncomment when typeless gears is completed
            #self.add_alias(self.application.fqdn)
            
            application.aliases.each { |fqdn| self.add_alias(fqdn) }
            dns = StickShift::DnsService.instance
            begin
              begin
                dns.deregister_application(application.name, application.domain.namespace)
              rescue Exception => e
                #ignoring
                Rails.logger.debug e
              end
              dns.register_application(application.name, application.domain.namespace, self.gears[0].public_hostname)
              dns.publish
            ensure
              dns.close
            end
          end
        rescue StickShift::NodeException => e
          result_io.append e.resultIO
          e.resultIO = result_io
          gears.delete gear
          new_gears.delete gear
          raise
        end
      end
      ssh_keys = self.application.app_ssh_keys.map{|k| k.attributes}
      ssh_keys += self.application.domain.owner.ssh_keys.map{|k| k.attributes}
      ssh_keys += CloudUser.find(self.application.domain.user_ids).map{|u| u.ssh_keys.map{|k| k.attributes}}.flatten
      begin
        result_io.append GroupInstance.update_configuration(ssh_keys, [], self.application.domain.env_vars, [], new_gears)
      rescue
        gear_ids = new_gears.map{|g| g._id.to_s}
        self.application.pending_ops.push(PendingAppOps.new(op_type: :update_configuration, args: {"group_instance_id" => _id.to_s, "gear_ids" => gear_ids}))
        self.component_instances.each do |component_instance_id|
          self.application.pending_ops.push(PendingAppOps.new(op_type: :configure_component_on_gears, args: {"group_instance_id" => _id.to_s, "gear_ids" => gear_ids, "component_instance_id" => component_instance_id}, flag_req_change: true))
        end
        raise
      end
      
      pending_component_ids = self.component_instances
      self.application.component_instances.find(self.component_instances).each do |component_instance|
        result_io.append configure_component_on_gears(component_instance, new_gears)
        if result_io.exitcode != 0
          gear_ids = new_gears.map{|g| g._id.to_s}
          pending_component_ids.each do |component_instance_id|
            self.application.pending_ops.push(PendingAppOps.new(op_type: :configure_component_on_gears, args: {"group_instance_id" => _id.to_s, "gear_ids" => gear_ids, "component_instance_id" => component_instance_id}, flag_req_change: true))
          end
          raise "Unable to complte configuration of #{component_instance.cartridge_name} on #{gear_ids.join(",")}"
        end
        pending_component_ids.delete component_instance._id
      end
      self.application.pending_ops.push(PendingAppOps.new(op_type: :execute_connections, args: {}))
    end
    
    #scale down
    if(gears.count > self.current_scale)
      GroupInstance.run_on_gears(self.gears[self.current_scale..gears.count], result_io, false) { |gear,result_io| result_io.append gear.destroy }
      self.application.pending_ops.push(PendingAppOps.new(op_type: :execute_connections, args: {}))      
    end
    
    result_io
  end
  
  # Configures the specified {ComponentInstance} on a set of {Gear}s. If any of the gears fail, the component is deconfigured from all the {Gear}s.
  #
  # == Parameters:
  # component_instance::
  #   {ComponentInstance} to configure.
  # gears::
  #   {Gear}s to configure the component on.
  #
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  def self.configure_component_on_gears(component_instance, gears)
    result_io = ResultIO.new
    begin
      run_on_gears(gears, result_io) { |gear,result_io| result_io.append gear.add_component(component_instance) }
    rescue Exception => e
      run_on_gears(gears, result_io, false) { |gear,result_io| result_io.append gear.remove_component(component_instance) }
    end
    result_io
  end
  
  # Configures an additional component instance to the gears of this group instance.
  # If the component is a singleton then it is added to only the first gear within the instance.
  #
  # == Parameters:
  # component_instance::
  #   {ComponentInstance} object representing the component to install
  def add_component(component_instance)
    gears = []
    if component_instance.is_singleton?
      self.singleton_instances.push component_instance._id
      gears = [self.gears.first]
    else
      self.component_instances.push component_instance._id
      gears = self.gears
    end
    self.save

    GroupInstance.configure_component_on_gears(component_instance, gears)
  end
  
  # Removes a component instance from the gears of this group instance.
  #
  # == Parameters:
  # component_instance::
  #   {ComponentInstance} object representing the component to remove
  def remove_component(component_instance)
    result_io = ResultIO.new
    gears = self.gears
    gears = [self.gears.first] if component_instance.is_singleton?
    GroupInstance.run_on_gears(gears, result_io, false) { |gear,result_io| result_io.append gear.remove_component(component_instance) }
    
    if result_io.exitcode == 0
      if component_instance.is_singleton?
        singleton_instances.delete component_instance._id
      else
        component_instance.delete component_instance._id
      end
    end
    self.save
    
    result_io
  end
  
  # Adds ssh keys to all gears within the group instance.
  #
  # == Parameters:
  # add_keys::
  #   Array of Hash containing name, type, content of the ssh keys
  # remove_keys::
  #   Array of Hash containing name, type, content of the ssh keys  
  # add_envs::
  #   Array of Hash containing key, value of the environment variables
  # remove_envs::
  #   Array of Hash containing key, value of the environment variables
  # gears::
  #   List of gears to apply these changes to
  #   @Note Used internally during create/scale-up operations
  def self.update_configuration(add_keys=[], remove_keys=[], add_envs=[], remove_envs=[], gears=nil)
    handle = RemoteJob.create_parallel_job
    tag = ""
    
    RemoteJob.run_parallel_on_gears(gears, handle) do |exec_handle, gear|
      add_keys.each     { |ssh_key| RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.get_add_authorized_ssh_key_job(ssh_key["content"], ssh_key["type"], ssh_key["name"])) } unless add_keys.nil?
      remove_keys.each  { |ssh_key| RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.get_remove_authorized_ssh_key_job(ssh_key["content"], ssh_key["name"])) } unless remove_keys.nil?

      add_envs.each     {|env|      RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.env_var_job_add(env["key"],env["value"]))} unless add_envs.nil?
      remove_envs.each  {|env|      RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.env_var_job_remove(env["key"]))} unless remove_envs.nil?
    end
    result_io = ResultIO.new
    RemoteJob.get_parallel_run_results(handle) do |tag, gear, output, status|
      result_io.resultIO << output
      result_io.exitcode = status
      if status != 0
        raise StickShift::NodeException.new("Error applying settings to gear: #{gear} with status: #{status} and output: #{output}", 143, result_io)
      end
    end
    result_io
  end
  
  # Destory all gears in this group instance and delete any DNS entries assocaited with them.
  #
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  #   failure != 0  
  def destroy_instance
    result_io = ResultIO.new
    if app_dns
      self.remove_alias(self.application.fqdn)
      dns = StickShift::DnsService.instance
      begin
        dns.deregister_application(application.name, application.domain.namespace)
        dns.publish
      rescue Exception => e
        Rails.logger.debug e.inspect
      ensure
        dns.close
      end
    end
    GroupInstance.run_on_gears(gears, result_io, false) { |gear,result_io| result_io.append gear.destroy }
    application.component_instances.in(_id: self.component_instances).union.in(_id: self.singleton_instances).delete
    result_io
  end

  # @return [Hash] a simplified hash representing this {GroupInstance} object which is used by {Application#compute_diffs}  
  def to_hash
    comps = resolve_component_instances.map{ |c| c.to_hash }
    {component_instances: comps, scale: {min: self.min, max: self.max, current: self.current_scale}, _id: _id}
  end
  
  # Register a DNS alias for the {GroupInstance}.
  # @note Alias will only be applied on the first gear of the {GroupInstance} and only if app_dns is true.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to associate with the application
  def add_alias(fqdn)
    gears[0].add_alias("abstract",fqdn) if app_dns
  end
  
  # Removes a DNS alias for the {GroupInstance}.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to remove.
  def remove_alias(fqdn)
    gears[0].remove_alias("abstract",fqdn) if app_dns    
  end
  
  # Convinience method to return a list of {ComponentInstance} objects in the {GroupInstance}
  #
  # == Returns:
  # Array of {ComponentInstance}s
  def resolve_component_instances
     component_instances.map{ |c| application.component_instances.find(c) } + singleton_instances.map{ |c| application.component_instances.find(c) }
  end
  
  protected
  
  # Run an operation on a list of gears on this group instance.
  #
  # == Parameters:
  # gears::
  #   Array of {Gear}s to run the operation on
  #
  # result_io::
  #   {ResultIO} object to collect stderr/stdout and exitcode from the operation
  #
  # fail_fast::
  #   Boolean to indicate if the operation should fail fast and raise an exception on the first failing gear.
  #
  # block::
  #   code block to run on all gears.
  #
  # == Returns:
  # successful runs::
  #   List of gears where the operation was succesful. Each entry is a Hash :gear -> {Gear}, :return -> exitcode of the operation
  # failed_runs::
  #   List of gears where the operation was not succesful. Each entry is a Hash :gear -> {Gear}, :exception -> exception raised by the operation
  #
  # == Raises:
  # {Exception} if a gear operation fails and fail_fast is true
  def self.run_on_gears(gears=nil, result_io = nil, fail_fast=true, &block)
    successful_runs = []
    failed_runs = []
    gears = self.gears if gears.nil?

    gears.dup.each do |gear|
      begin
        retval = block.call(gear, result_io)
        successful_runs.push({:gear => gear, :return => retval})
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.inspect
        failed_runs.push({:gear => gear, :exception => e})
        if (!result_io.nil? && e.kind_of?(StickShift::SSException) && !e.resultIO.nil?)
          result_io.append(e.resultIO)
        end
        if fail_fast
          raise Exception.new({:successful => successful_runs, :failed => failed_runs, :exception => e})
        end
      end
    end
    [successful_runs,failed_runs]
  end  
end
