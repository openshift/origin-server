module RestApi
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current["rest_api_call_runtime"] = value
    end
    def self.runtime
      Thread.current["rest_api_call_runtime"] ||= 0
    end
    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end

    def request(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      name = '%s (%.1fms)' % ['OpenShift API', event.duration]

      call = "#{color(event.payload.delete(:method), BOLD, true)} #{event.payload.delete(:request_uri)}"

      result = event.payload[:result]
      query = {:code => result.code}.map{ |k,v| "#{k}: #{color(v, BOLD, true)}" }.join(', ')

      debug "  #{color(name, BLUE, true)} #{call} [ #{query} ]"
    end
  end
end

