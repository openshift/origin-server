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
    custom_id = attrs[:custom_id]
    attrs.delete(:custom_id)
    super(attrs, options)
    self._id = custom_id unless custom_id.nil?
  end
  
  def create_gears(gear_ids=[])
    result_io = ResultIO.new
    gear_ids.each do |gear_id|
      return if self.gears.where(_id: gear_id).count == 1
      
      gear = Gear.new
      gear._id = gear_id
      #TODO: Remove when typeless gears is completed
      if(app_dns && gear_id == application._id.to_s)
        gear.name = application.name
      else
        gear.name = gear._id.to_s[0..9]
      end
      #END-TODO#
      
      gears.push gear
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
        raise
      rescue Exception => e
        gear.destroy_gear
        raise
      end
    end
    result_io
  end
  
  def destroy_gears(gear_ids=[])
    result_io = ResultIO.new
    self.gears.find(gear_ids).each do |gear|
      if self.gears[0] == gear && self.app_dns
        begin
          dns.deregister_application(application.name, application.domain.namespace)
        rescue Exception => e
          #ignoring
          Rails.logger.debug e
        end
      end
      result_io.append gear.destroy_gear
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
      #self.remove_alias(self.application.fqdn)
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
    GroupInstance.run_on_gears(gears, result_io, false) { |gear,result_io| result_io.append gear.destroy_gear }
    application.component_instances.in(_id: self.component_instances).union.in(_id: self.singleton_instances).delete
    result_io
  end

  # @return [Hash] a simplified hash representing this {GroupInstance} object which is used by {Application#compute_diffs}  
  def to_hash
    comps = resolve_component_instances.map{ |c| c.to_hash }
    {component_instances: comps, scale: {min: self.min, max: self.max, user_min: self.user_min, user_max: self.user_max, current: self.gears.length}, _id: _id}
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
