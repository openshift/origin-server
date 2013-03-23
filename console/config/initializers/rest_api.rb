require 'rest_api'
require 'rest_api/log_subscriber'
require 'rest_api/railties/controller_runtime'

RestApi::LogSubscriber.attach_to :active_resource

if Rails.env.development?
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

