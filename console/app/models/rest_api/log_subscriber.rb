module RestApi
  module RequestDumper
    def request_id(request)
      request.to_hash['x-request-id'].first rescue nil
    end

    def dump_body(result, color)
      body = (result.body || "").strip
      return unless body.size > 0

      msg =  case result.content_type
             when "application/json"
               JSON.pretty_generate(sanitize(JSON.parse(body))).lines
             end
      without_pid {
        [*msg].each do |line|
          logger.debug "#{color(line.chomp,color)}"
        end
      }
    end

    #TODO: This may need to be changed to be recursive
    def sanitize(hash)
      keys = %w(password old_password password_confirmation)
      hash.inject({}){|h,(k,v)| h[k] = (keys.include?(k) ? "<sanitized>" : v); h}
    end

    def without_pid(&block)
      old_omit_pid = logger.formatter.omit_pid
      logger.formatter.omit_pid = true
      yield
    ensure
      logger.formatter.omit_pid = old_omit_pid
    end
  end

  class HTTPSubscriber < ActiveSupport::LogSubscriber
    include RequestDumper

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
      # Do not modify runtime for REST API logging, since this would be a duplicate
      (self.class.runtime += event.duration) unless event.payload.delete(:rest_api)
      return unless logger.debug?

      name = '%s (%.1fms)' % ['OpenShift API', event.duration]

      call = "#{color(event.payload.delete(:method), BOLD, true)} #{event.payload.delete(:request_uri)}"

      msg = "  #{color(name, BLUE, true)} #{call} "

      result = event.payload[:result]

      if result
        query = {:code => result.code}
        if(rid = request_id(result))
          query[:rid] = rid[0,8]
        end
        query = query.map{ |k,v| "#{k}: #{color(v, BOLD, true)}" }.join(', ')
        msg << "[ #{query} ] "
      end

      debug msg
    end
  end

  class RestSubscriber < HTTPSubscriber
    def request(event)
      event.payload[:rest_api] = true
      if (request = event.payload[:request])
        rid = event.payload[:rid]
        stored_requests[rid] = request unless request.body.blank?
      else
        result = event.payload[:result]
        rid = request_id(result)
        request = stored_requests.delete(rid)
        return unless RestApi.site.host == URI.parse(event.payload[:request_uri]).hostname
        # TODO: Need to make sure this doesn't mess with any of the duration/runtime stuff
        super(event)
        without_pid {
          if(request)
            dump_body(request,YELLOW)
            logger.debug("-" * 10)
          end
          dump_body(result,CYAN)
        }
      end
    end

    protected
    def stored_requests
      @@stored_requests ||= {}
    end
  end
end
