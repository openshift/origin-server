# Class to perform gear operations in parallel on multiple gears.
# @!attribute [r] cartridge
#   @return [String] The name of the cartridge to perform the operation on.
# @!attribute [r] action
#   @return [String] The name of the action to perfrom
# @!attribute [r] args
#   @return [Array[String]] arguments to pass to the action hook
class RemoteJob < OpenShift::Model
  attr_accessor :cartridge, :action, :args
  
  # Creates a new RemoteJob
  #
  # == Parameters:
  # target::
  #   The {Cartridge} name
  # action::
  #   The action to perform
  # args::
  #   Array of arguments to pass to the hook
  def initialize(target, action, args)
    self.cartridge = target
    self.action = action
    self.args = args
  end
  
  # Creates a new Parallel job handle
  #
  # == Returns:
  # New parallel job handle. Currently represented by a Hash
  def self.create_parallel_job
    return { }
  end

  # Calls the provided block to generate RemoteJob entries for each gear and executes those jobs in parallel.
  # This method provides a convinient way to combine {RemoteJob#add_parallel_job} and {RemoteJob#execute_parallel_jobs}
  #
  # == Parameters:
  # gears::
  #   The {Gear}s to run the operations on
  # handle::
  #   (optional) The parallel job handle which may contain other jobs that needs to be run.
  # block::
  #   The block of code which add a job for each gear using {RemoteJob#add_parallel_job}
  #
  # == Block arguments:
  #
  # exec_handle::
  #   The parallel job handle
  # gear::
  #   The {Gear} to create a {RemoteJob} for
  def self.run_parallel_on_gears(gears, handle=nil, &block)
    handle = create_parallel_job if handle.nil?
    gears.each { |gear|
      block.call(handle, gear)
    }
    execute_parallel_jobs(handle)
  end
  
  # Executes all jobs in the parallel job handle
  #
  # == Parameters:
  # handle::
  #   The parallel job handle
  def self.execute_parallel_jobs(handle)
    begin
      OpenShift::ApplicationContainerProxy.execute_parallel_jobs(handle)
    rescue Exception=>e
      Rails.logger.error e.message
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace.inspect        
      raise e
    end    
  end

  # Add a new job to the parallel job handle
  #
  # == Parameters:
  # handle::
  #   The parallel job handle
  # tag::
  #   Tag to identify the job (optional)
  # gear::
  #   The gear to run the job on
  # rjob::
  #   The {RemoteJob} to add to the handle
  #
  # == Returns:
  # Parallel job handle
  def self.add_parallel_job(handle, tag, gear, rjob)
    tag = tag || ""
    parallel_job = { 
                     :tag => tag,
                     :gear => gear._id.to_s,
                     :job => { :cartridge => rjob.cartridge, :action => rjob.action, :args => rjob.args },
                     :result_stdout => "",
                     :result_stderr => "",
                     :result_exit_code => ""
                   }
    job_list = handle[gear.get_proxy.id] || []
    job_list << parallel_job
    handle[gear.get_proxy.id] = job_list
    handle
  end

  # Method to process the parallel job results. It calls the block with the output of each job.
  #
  # == Parameters:
  # handle::
  #   The parallel job handle
  # block::
  #   The code block to call for each job
  #
  # == Block arguments:
  # tag::
  #   The identifier tag for the job
  # gear::
  #   The gear the job was performed on
  # stdout::
  #   The standard out output from the hook execution
  # exitcode::
  #   The exitcode from the hook execution
  def self.get_parallel_run_results(handle, &block)
    handle.each { |id, job_list|
      job_list.each { |parallel_job|
        block.call(parallel_job[:tag], parallel_job[:gear], parallel_job[:result_stdout], parallel_job[:result_exit_code])
      }
    }
  end
end
