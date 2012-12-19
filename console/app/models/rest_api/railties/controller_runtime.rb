module RestApi
  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

      protected

      attr_internal :ra_runtime

      def process_action(action, *args)
        RestApi::HTTPSubscriber.reset_runtime
        super
      end

      def cleanup_view_runtime
        rt_before_render = RestApi::HTTPSubscriber.reset_runtime
        runtime = super
        rt_after_render = RestApi::HTTPSubscriber.reset_runtime
        self.ra_runtime = rt_before_render + rt_after_render
        runtime - rt_after_render
      end

      def append_info_to_payload(payload)
        super
        payload[:ra_runtime] = ra_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, runtime = super, payload[:ra_runtime]
          messages << ("OpenShift API: %.1fms" % runtime.to_f) if !runtime.nil? && runtime > 0
          messages
        end
      end
    end
  end
end
