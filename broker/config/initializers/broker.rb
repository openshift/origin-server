require 'backburner'

Backburner.configure do |config|
  config.beanstalk_url    = ["beanstalk://172.17.42.1"]
  config.tube_namespace   = "broker.tube"
  config.on_error         = lambda { |e| puts e }
  config.max_job_retries  = 0 # default 0 retries
  config.retry_delay      = 5 # default 5 seconds
  config.default_priority = 65536
  config.respond_timeout  = 120
  config.default_worker   = Backburner::Workers::ThreadsOnFork
  config.logger           = Logger.new(STDOUT)
  config.primary_queue    = "application-jobs"
  config.priority_labels  = { :custom => 50, :useless => 1000 }
end

