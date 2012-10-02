# stickshift-node/config has been moved to stickshift-common/config.  This stub
# remains for code in li that still requires the former.  Once everything has
# migrated to stickshift-common/config, this file can be deleted.
# -- Miciah, 2012-10-02

require 'rubygems'

require 'stickshift-common/config'

module StickShift
  class Config

    # This is a bit of a hack.  The old StickShift::Config was a singleton
    # object, and so users would use StickShift::Config.instance to get it.
    # Here, we define .instance to return a new instance.  Hopefully, nothing
    # is relying on the standard singleton behavior whereby .instance always
    # returns the same instance.
    def instance
      StickShift::Config.new
    end
  end
end
