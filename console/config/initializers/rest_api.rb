if RestApi::Configuration.activate(Rails.application.config.stickshift)
  info = RestApi.info
  Rails.logger.info "Connected to #{info.url} with version #{info.version}"
end

