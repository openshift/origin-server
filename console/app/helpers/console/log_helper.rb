module Console::LogHelper

  # Common - request id, user agent, ip address
  def user_action(action, success=true, options={}, message=nil)
    action_info = {
      :user_agent => request.user_agent,
      :ip_address => request.remote_ip,
      :request_id => request.uuid
    }.merge(options)

    status = success ? 'SUCCESS' : 'FAILURE'
    now = Time.new
    date = now.strftime('%Y-%m-%d')
    time = now.strftime('%H:%M:%S')

    optional_params = action_info.map { |k,v| "#{k.upcase}=#{v}" }.join(' ')
    Rails.logger.info("[user_action] #{status} DATE=#{date} TIME=#{time} ACTION=#{action.upcase} #{optional_params} #{message || ''}".strip)
  end

end
