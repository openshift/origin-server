require 'openshift-origin-node/utils/node_logger'
require 'parallel'

module OpenShift
  module Runtime
    # Provides wrappers around some threading constructs used by the platform in order
    # to facilitate logging of thread-local context provided by NodeLogger.
    #
    # These functions are meant to be transparent wrappers of the target method call,
    # but will inject items from +NodeLogger#context+ in the current thread to the
    # +NodeLogger#context+ of the new thread.
    #
    # This allows logging context entries to cross thread boundaries.
    module Threads
      module Parallel
        # Delegates to +Parallel#map+ from the +parallel+ gem.
        def self.map(*args, &block)
          parent = Thread.current
          ::Parallel.map(*args) do |item|
            Thread.current[NodeLogger::CONTEXT_KEY] = parent[NodeLogger::CONTEXT_KEY]
            block.call(item)
          end
        end
      end

      # Delegates to the stdlib +Thread#new+ method.
      def self.new_thread(*args, &block)
        parent = Thread.current
        Thread.new(*args) do |*items|
          Thread.current[NodeLogger::CONTEXT_KEY] = parent[NodeLogger::CONTEXT_KEY]
          block.call(*items)
        end
      end
    end
  end
end
