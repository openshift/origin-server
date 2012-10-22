# openshift-origin-node/config has been moved to openshift-origin-common/config.
# This stub remains for code in li that still requires the former.  Once
# everything has migrated to openshift-common/config, this file can be
# deleted.  -- Miciah, 2012-10-02

require 'rubygems'

require 'openshift-origin-common'

module OpenShift
  class Config
    # This is a bit of a hack.  The old OpenShift::Config was a singleton
    # object, and so users would use OpenShift::Config.instance to get it.
    # Here, we define .instance to return a new instance.  Hopefully, nothing
    # is relying on the standard singleton behavior whereby .instance always
    # returns the same instance.
    def self.instance
      OpenShift::Config.new
    end
  end
end
