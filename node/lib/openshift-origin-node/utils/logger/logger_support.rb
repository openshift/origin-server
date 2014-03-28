module OpenShift
  module Runtime
    module NodeLogger
      # This module supports NodeLogger implementations.
      module LoggerSupport
        # Formats +entry+ by prepending the string containing the contents
        # of +NodeLogger.context+ in the form +[k=v,k=v,k=v, ...]+.
        #
        # Configuration is drive by +@config+ which is assumed to be defined
        # as a +Config+-like object.
        #
        # The context entries to print may be configured by the +PLATFORM_LOG_CONTEXT_ATTRS+
        # config key. The value is a comma-delimited list from the following attributes:
        #
        #   action_method
        #   request_id
        #   container_uuid
        #   app_uuid
        #
        # If no context attribute configuration is present, all context attributes will be
        # printed.
        #
        # Formatting is only enabled if the +PLATFORM_LOG_CONTEXT_ENABLED+ config value is +1+.
        def format(entry)
          @context_enabled ||= defined?(@config) && (@config.get('PLATFORM_LOG_CONTEXT_ENABLED') || '0').to_i == 1

          return entry unless @context_enabled

          @context_attrs ||= defined?(@config) ? (@config.get('PLATFORM_LOG_CONTEXT_ATTRS') || '').split(',') : []

          if @context_attrs.empty?
            context = NodeLogger.context.map {|k,v| "#{k}=#{v}"}.join(',')
          else
            context = @context_attrs.map {|k|
              next unless v = NodeLogger.context[k.to_sym]
              "#{k}=#{v}"
            }.compact.join(',')
          end

          "[#{context}] #{entry}"
        end
      end
    end
  end
end
