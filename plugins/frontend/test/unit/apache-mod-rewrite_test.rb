require_relative '../test_helper'

require_relative '../../apache-mod-rewrite/lib/openshift/runtime/frontend/http/plugins/apache-mod-rewrite'

class ApacheModRewriteTest < PluginTestCase

  def test_ctor
    object = OpenShift::Runtime::Frontend::Http::Plugins::ApacheModRewrite.new(@container_uuid,
                                                                               'apachemodrewritetest.example.com',
                                                                               'apachemodrewritetest_app',
                                                                               'apachemodrewritetest_namespace')
    refute_nil object
  end
end
