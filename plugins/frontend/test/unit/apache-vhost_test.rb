require_relative '../test_helper'

require_relative '../../apache-vhost/lib/openshift/runtime/frontend/http/plugins/apache-vhost'

class ApacheVirtualHostsTest < PluginTestCase
  def test_ctor
    object = OpenShift::Runtime::Frontend::Http::Plugins::ApacheVirtualHosts.new(@container_uuid,
                                                                               'apachevirtualhoststest.example.com',
                                                                               'apachevirtualhoststest_app',
                                                                               'apachevirtualhoststest_namespace')
    refute_nil object
  end
end
