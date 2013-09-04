require_relative '../test_helper'

require_relative '../../apache-mod-rewrite/lib/openshift/runtime/frontend/http/plugins/apache-mod-rewrite'

class ApacheModRewriteFunctionalTest < PluginTestCase
  def setup
    @connections = [
        ["", "127.0.0.1:8080", {"websocket" => 1, "connections" => 1, "bandwidth" => 2}],
        ["/nosocket", "127.0.0.1:8080", {}],
        ["/gone", "", {"gone" => 1}],
        ["/forbidden", "", {"forbidden" => 1}],
        ["/noproxy", "", {"noproxy" => 1}],
        ["/redirect", "/dest", {"redirect" => 1}],
        ["/file", "/dest.html", {"file" => 1}],
        ["/tohttps", "/dest", {"tohttps" => 1}]
    ]
  end

  def test_ctor
    plugin = OpenShift::Runtime::Frontend::Http::Plugins::ApacheModRewrite.new(@container_uuid,
                                                                               'apachemodrewritetest.example.com',
                                                                               'apachemodrewritetest_app',
                                                                               'apachemodrewritetest_namespace')
    refute_nil plugin
  end

  def test_connect
    plugin = OpenShift::Runtime::Frontend::Http::Plugins::ApacheModRewrite.new(@container_uuid,
                                                                               'apachemodrewritetest.example.com',
                                                                               'apachemodrewritetest_app',
                                                                               'apachemodrewritetest_namespace')
    plugin.connect(@connections.first)
    results = plugin.connections
    refute_nil results
    assert_equal(@connections.first, results.first)
  end
end
