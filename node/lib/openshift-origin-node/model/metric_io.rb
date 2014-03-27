module OpenShift
  module Runtime
    class MetricIO < IO

      attr_accessor :buffer_size, :file_descriptor
      # This method should take in the context of the metrics running i.e. gear_uuid, app_uuid etc
      def initialize fd, buffer_size
        super fd
        @buffer_size = buffer_size
      end

      # Must implement this method for oo-spawn to be able to use it
      # Override
      def << string
        string.split("\n").each do |line|
          remainder_tokens = line.split("\s").delete_if{|tok| tok.bytesize > @buffer_size}
          while !remainder_tokens.empty?
              result, remainder_tokens = truncate_to_length(remainder_tokens)
              super(result)
          end
        end
      end

      # Returns string and array
      def truncate_to_length tokens
        trunc_to = tokens.size - 1
        while tokens[0..trunc_to].join("\s").bytesize > @buffer_size do
          trunc_to -= 1
        end
        return tokens[0..trunc_to].join("\s"), tokens[(trunc_to + 1) .. -1]
      end
    end
  end
end
