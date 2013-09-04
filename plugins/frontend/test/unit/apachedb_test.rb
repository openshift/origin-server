require_relative '../test_helper'

require_relative '../../apachedb/lib/openshift/runtime/frontend/http/plugins/apachedb'

class FauxApacheDB < OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
  self.MAPNAME = 'faux'
  self.LOCK    = Mutex.new
end

class ApacheDBTest < PluginTestCase
  def test_ctor_super_class
    assert_raises NotImplementedError do
      OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB.new()
    end
  end

  def test_apachedb_json
    File.expects(:open).with('/etc/httpd/conf.d/openshift/faux.txt', 0).returns([])
    object = FauxApacheDB.new()
    refute_nil object
  end
end
