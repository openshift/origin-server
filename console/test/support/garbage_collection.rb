class ActiveSupport::TestCase
  #setup :begin_gc_deferment
  #teardown :reconsider_gc_deferment

  DEFERRED_GC_THRESHOLD = (ENV['DEFER_GC'] || 1.0).to_f

  @@last_gc_run = Time.now

  def begin_gc_deferment
    GC.disable if DEFERRED_GC_THRESHOLD > 0
  end

  def reconsider_gc_deferment
    if DEFERRED_GC_THRESHOLD > 0 && Time.now - @@last_gc_run >= DEFERRED_GC_THRESHOLD
      GC.enable
      GC.start
      GC.disable

      @@last_gc_run = Time.now
    end
  end
end