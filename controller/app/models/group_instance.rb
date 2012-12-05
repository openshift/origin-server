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
# @!attribute [r] :gear_size
#   @return [String] Gear size of all gears under this {GroupInstance}
# @!attribute [r] gears
#   @return [Array[Gear]] List of gears that are part of this {GroupInstance}
# @!attribute [r] app_dns
#   @return [Boolean] Indicates if the group instance hosts the web_proxy component and has the Application DNS pointed to it.
class GroupInstance
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  field :gear_size, type: String, default: "small"
  field :addtl_fs_gb, type: Integer, default: 0
  embeds_many :gears, class_name: Gear.name
  
  attr_accessor :min, :max
  
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
  
  def component_instances
    all_component_instances.select{|c| !c.is_singleton?}
  end
  
  def singleton_instances
    all_component_instances.select{|c| c.is_singleton?}
  end
  
  def all_component_instances
    application.component_instances.where(group_instance_id: self._id)
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
        raise OpenShift::NodeException.new("Error applying settings to gear: #{gear} with status: #{status} and output: #{output}", 143, result_io)
      end
    end
    result_io
  end

  # @return [Hash] a simplified hash representing this {GroupInstance} object which is used by {Application#compute_diffs}  
  def to_hash
    comps = all_component_instances.map{ |c| c.to_hash }
    {component_instances: comps, scale: {current: self.gears.length, additional_filesystem_gb: addtl_fs_gb, gear_size: gear_size}, _id: _id}
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
  #   List of gears where the operation was successful. Each entry is a Hash :gear -> {Gear}, :return -> exitcode of the operation
  # failed_runs::
  #   List of gears where the operation was not successful. Each entry is a Hash :gear -> {Gear}, :exception -> exception raised by the operation
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
        if (!result_io.nil? && e.kind_of?(OpenShift::OOException) && !e.resultIO.nil?)
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
