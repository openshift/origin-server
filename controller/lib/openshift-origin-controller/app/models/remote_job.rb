
class RemoteJob < OpenShift::Model
  attr_accessor :cartridge, :action, :args
  
  def initialize(target, action, args)
    self.cartridge = target
    self.action = action
    self.args = args
  end
  
  
  def self.create_parallel_job
    return { }
  end

  def self.run_parallel_on_gears(gears, handle, &block)
    gears.each { |gear|
      block.call(handle, gear)
    }
    # now execute
    begin
      OpenShift::ApplicationContainerProxy.execute_parallel_jobs(handle)
    rescue Exception=>e
      Rails.logger.error e.message
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace.inspect        
      raise e
    end
  end

  def self.add_parallel_job(handle, tag, gear, rjob)
    parallel_job = { 
                     :tag => tag,
                     :gear => gear.uuid,
                     :job => { :cartridge => rjob.cartridge, :action => rjob.action, :args => rjob.args },
                     :result_stdout => "",
                     :result_stderr => "",
                     :result_exit_code => ""
                   }
    job_list = handle[gear.get_proxy.id] || []
    job_list << parallel_job
    handle[gear.get_proxy.id] = job_list
  end

  def self.get_parallel_run_results(handle, &block)
    handle.each { |id, job_list|
      job_list.each { |parallel_job|
        block.call(parallel_job[:tag], parallel_job[:gear], parallel_job[:result_stdout], parallel_job[:result_exit_code])
      }
    }
  end

end
