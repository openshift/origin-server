require 'thread'

module OpenShift
  module Runtime
    module Utils
      #
      # This class provides a very simple countdown object which can be used
      # to drive time-boxed operations.
      #
      # Upon initialization, the current time is noted, and calls to +remaining+
      # will be relative to the start time and supplied +duration+ (expressed in
      # seconds).
      #
      class Hourglass
        attr_reader :end_time

        def initialize(duration)
          @duration = duration
          @start_time = Time.now
          @end_time = @start_time + @duration
        end

        #
        # Returns the number of seconds elapsed since the start time.
        #
        def elapsed
          (Time.now - @start_time).round
        end

        #
        # Returns the number of seconds remaining until expiration, or zero
        # if the hourglass has expired.
        #
        def remaining
          [0, @duration - elapsed].max
        end

        #
        # Returns +true+ if the duration has been exceeded, otherwise false.
        #
        def expired?
          remaining.zero?
        end

        def to_s
          "hourglass_remaining=#{remaining}"
        end
      end
    end
  end
end
