begin
  info = RestApi.info
  Rails.logger.info "Connected to #{info.url} with version #{info.version}"
rescue Exception => e
  Rails.logger.warn e.message
end

