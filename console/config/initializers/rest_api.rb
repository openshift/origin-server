require 'rest_api'
require 'rest_api/log_subscriber'
require 'rest_api/railties/controller_runtime'

RestApi::HTTPSubscriber.attach_to :active_resource

if RestApi::debug?
  # Get the log path from the Rails config
  log_paths = [
    File.dirname(Rails.configuration.paths['log'].first),
    File.dirname(Rails.configuration.paths['tmp'].first),
    Dir.tmpdir
  ]

  log_path = log_paths.select{|x| File.writable?(x) }.first

  if log_path.nil?
    Rails.logger.debug "Cannot create logfile for REST API logging, skipping"
  else
    path = File.join(log_path,"rest_api.log")
    # Create our new logger
    rest_logger = ActiveSupport::TaggedLogging.new(Logger.new(path))
    Rails.logger.debug "Created REST API logger at #{path}"

    # Use the same formatter as Rails
    rest_logger.formatter = Formatter.new
    # Set our logger for the subscriber
    RestApi::RestSubscriber.logger = rest_logger
    # Attach our logger to see requests
    RestApi::RestSubscriber.attach_to :active_resource
    RestApi::RestSubscriber.attach_to :http
  end
end

unless Rails.env.production?
  begin
    info = RestApi.info
    Rails.logger.info "Connected to #{info.url} with version #{info.version}"
  rescue Exception => e
    puts e if Rails.env.development?
    Rails.logger.warn e.message
  end
end

ActiveSupport.on_load(:action_controller) do
  include RestApi::Railties::ControllerRuntime
end

ActiveSupport.on_load(:action_controller) do
  RestApi::Base.instantiate_observers
end

