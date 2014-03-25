module OpenShift
  module Runtime
    class MetricIO < IO

      attr_accessor :buffer_size, :file_descriptor
      # This method should take in the context of the metrics running i.e. gear_uuid, app_uuid etc
      def initialize fd, buffer_size, context_info={}
        super fd
        @buffer_size = buffer_size
      end

      # Must implement this method for oo-spawn to be able to use it
      # Override
      def << string
        string.split("\n").each do |line|
          super(truncate_to_length(line))
        end
      end

      def truncate_to_length string
        tokens = string.split("\s")
        trunc_to = tokens.size - 1
        while tokens[0..trunc_to].join("\s").bytesize > @buffer_size do
          trunc_to -= 1
        end
        tokens[0..trunc_to].join("\s")
      end
    end
  end
end
