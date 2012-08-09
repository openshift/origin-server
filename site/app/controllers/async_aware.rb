#
# Prototype support for simple parallel requests.  It is the callers
# responsibility to ensure that blocks are side-effect free.
#
module AsyncAware
  extend ActiveSupport::Concern

  def async(&block)
    (@threads ||= []) << Thread.start do
      begin
        Thread.current[:out] = yield block
      rescue StandardError => e
        Thread.current[:out] = e
      end
    end
  end
  def join(limit=5)
    threads = begin
      @threads.each{ |t| t.join(limit) }
    ensure
      @threads.each(&:kill)
      @threads = nil
    end
    threads.map{ |t| t[:out] }.compact
  end

  #
  # Throw the first exception encountered
  #
  def join!(limit=5)
    join(limit).tap do |results|
      exceptions = results.select{ |r| r.is_a? StandardError }
      exceptions[1..-1].each{ |e| Rails.logger.error "#{e.class} (#{e})\n  #{Rails.backtrace_cleaner.clean(e.backtrace).join("\n  ")}" } if exceptions.size > 1
      raise exceptions.first unless exceptions.empty?
    end
  end
end
