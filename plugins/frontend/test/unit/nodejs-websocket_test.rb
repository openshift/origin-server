require_relative '../test_helper'

require_relative '../../nodejs-websocket/lib/openshift/runtime/frontend/http/plugins/nodejs-websocket'

class NodeJSWebsocketTest < PluginTestCase
  def test_ctor
      OpenShift::Runtime::Frontend::Http::Plugins::NodeJSWebsocket.new(@container_uuid,
                                                                       'nodejswebsockettest.example.com',
                                                                       'nodejswebsockettest_app',
                                                                       'nodejswebsockettest_namespace')
  end
end
