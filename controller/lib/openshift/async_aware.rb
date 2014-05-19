#
# Prototype support for simple parallel requests.  It is the callers
# responsibility to ensure that blocks are side-effect free.
#
module OpenShift
  module AsyncAware
    extend ActiveSupport::Concern

    def async(&block)
      @threads ||= []
      index = @threads.length
      @threads << Thread.start do
        begin
          Thread.current[:index] = index
          Thread.current[:out] = yield block
        rescue => e
          Thread.current[:out] = e
        end
      end
    end
    def join(limit=nil)
      running = @threads
      t1 = Time.now.to_f

      threads = begin
        @threads.map{ |t| limit ? t.join(limit - (Time.now.to_f - t1)) : t.join }
      ensure
        @threads.each(&:kill)
        @threads = nil
      end

      #puts                  "**** Joined #{Time.now.to_f - t1} (limit=#{limit})"
      #puts running.map{ |t| "     #{t.inspect}: #{threads.include?(t) ? "" : "(did not finish) "} (index=#{t[:index]}) #{t[:out].inspect}" }.join("\n")

      running.map do |t| 
        if threads.include?(t) 
          t[:out]
        else
          begin; raise(ThreadTimedOut.new(t, limit)); rescue => e; e; end
        end
      end
    end

    #
    # Throw the first exception encountered
    #
    def join!(limit=nil)
      join(limit).tap do |results|
        exceptions = results.select{ |r| r.is_a? StandardError }
        exceptions[1..-1].each{ |e| Rails.logger.error "#{e.class} (#{e})\n  #{Rails.backtrace_cleaner.clean(e.backtrace).join("\n  ")}" } if exceptions.size > 1
        raise exceptions.first unless exceptions.empty?
      end
    end

    class ThreadTimedOut < StandardError
      attr_reader :thread
      def initialize(thread, timeout)
        @thread, @timeout = thread, timeout
      end
      def to_s
        "The thread #{thread.inspect} (index=#{thread[:index]}) did not complete within #{@timeout} seconds."
      end
    end
  end
end