begin
  info = RestApi.info
  Rails.logger.info "Connected to #{info.url} with version #{info.version}"
rescue Exception => e
  raise e if Rails.env.development?
  Rails.logger.warn e.message
end

