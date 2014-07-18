#!/usr/bin/env oo-ruby
#--
# Copyright 2013 Red Hat, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
#
# Test the OpenShift frontend_proxy model
#
require_relative '../test_helper'
require 'fileutils'

module OpenShift; end

# Run unit test manually
# ruby -I node/lib:common/lib node/test/unit/frontend_proxy_test.rb
class FrontendProxyTest < OpenShift::NodeTestCase

  def setup
    @ports_begin = 35531
    @ports_per_user = 5
    @uid_begin = 500
    @wrap_uid  = 6501

    @config.stubs(:get).with("PORT_BEGIN").returns(@ports_begin.to_s)
    @config.stubs(:get).with("PORTS_PER_USER").returns(@ports_per_user.to_s)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid_begin.to_s)
  end

  # Simple test to validate the port range computation given
  # a certain UID.
  def test_port_range
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    assert_equal (@ports_begin ... (@ports_begin + @ports_per_user)), proxy.port_range(500)
  end

  # Ensure that the wrapped UID has the same values
  def test_wrap_port_range
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    assert_equal (@ports_begin ... (@ports_begin + @ports_per_user)), proxy.port_range(@wrap_uid)
  end

  # Verify a valid mapping request is mapped to a port.
  def test_valid_add
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['', '', 0]).once

    mapped_port = proxy.add(uid, '127.0.0.1', 8080)
    assert_equal 35531, mapped_port
  end

  # When adding the same mapping twice, the existing port mapping
  # should be returned immediately.
  def test_valid_add_twice
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['', '', 0]).once

    mapped_port = proxy.add(uid, '127.0.0.1', 8080)
    assert_equal 35531, mapped_port

    proxy.expects(:system_proxy_show).returns("127.0.0.1:8080").once
    mapped_port = proxy.add(uid, '127.0.0.1', 8080)

    assert_equal 35531, mapped_port
  end

  # Ensures that a non-zero return code from a system proxy set
  # attempt during an add operation raises an exception.
  def test_add_system_error
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['Stdout', 'Stderr', 1]).once

    assert_raises OpenShift::Runtime::FrontendProxyServerException do
      proxy.add(uid, '127.0.0.1', 8080)
    end
  end

  # Verifies that an exception is thrown if all ports in the given
  # UID's range are already mapped to an address.
  def test_out_of_ports_during_add
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns("127.0.0.1:9000").times(@ports_per_user)
    proxy.expects(:system_proxy_set).never

    assert_raises OpenShift::Runtime::FrontendProxyServerException do
      proxy.add(uid, '127.0.0.1', 8080)
    end
  end

  # Verifies that a successful system proxy delete is executed for
  # an existing mapping.
  def test_delete_success
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).with(35531).returns("127.0.0.1:8080").once
    proxy.expects(:system_proxy_delete).with(35531).returns(['', '', 0]).once

    proxy.delete(uid, "127.0.0.1", 8080)
  end

  # Ensures that no system proxy delete is attempted when no mapping
  # to the requested address is found.
  def test_delete_nonexistent
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).at_least_once
    proxy.expects(:system_proxy_delete).never

    proxy.delete(uid, "127.0.0.1", 8080)
  end

  # Verifies an exception is raised when a valid delete attempt to the
  # system proxy returns a non-zero exit code.
  def test_delete_failure
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).with(35531).returns("127.0.0.1:8080").once
    proxy.expects(:system_proxy_delete).with(35531).returns(['Stdout', 'Stderr', 1]).once

    assert_raises OpenShift::Runtime::FrontendProxyServerException do
      proxy.delete(uid, "127.0.0.1", 8080)
    end
  end

  # Tests that a successful delete of all proxy mappings for the UID
  # results in a batch of 5 ports being sent to the system proxy command.
  def test_delete_all_for_uid_success
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    uid = 500
    ports = [1,2,3]

    proxy.expects(:port_range).with(uid).once.returns(ports)
    proxy.expects(:delete_all).with(ports,anything).once.returns(nil)

    proxy.delete_all_for_uid(uid, false)
  end

  def test_delete_all_for_uid_failure
    proxy = OpenShift::Runtime::FrontendProxyServer.new
    err = assert_raises RuntimeError do
      proxy.delete_all_for_uid(nil)
    end
    assert_equal "No UID specified", err.message
  end

  def test_delete_all_success
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    ports = [1,2,3]

    proxy.expects(:system_proxy_delete).with(*ports).returns(['', '', 0]).once

    assert_equal 0, proxy.delete_all(ports)
  end

  def test_delete_all_failure_missing_uid
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    err = assert_raises RuntimeError do
      proxy.delete_all(nil)
    end

    assert_equal "No proxy ports specified", err.message
  end

  # Ensures that a non-zero response from the system proxy delete call
  # and the ignore errors flag disables results in an exception bubbling.
  def test_delete_all_failure
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    ports = [1,2,3]

    proxy.expects(:system_proxy_delete).with(*ports).returns(['Stdout', 'Stderr', 1]).once

    err = assert_raises OpenShift::Runtime::FrontendProxyServerException do
      proxy.delete_all(ports, false)
    end

    assert_equal "System proxy delete of port(s) [1, 2, 3] failed(1): stdout: Stdout stderr: Stderr", err.message
  end

  def test_delete_all_failure_ignore
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    ports = [1,2,3]

    proxy.expects(:system_proxy_delete).with(*ports).returns(['Stdout', 'Stderr', 1]).once
    proxy.logger.expects(:warn).with(regexp_matches(/^System proxy delete of port/)).once

    assert_equal 1,  proxy.delete_all(ports)
  end

  # Verify the command line constructed by the system proxy delete
  # given a variety of arguments.
  def test_system_proxy_delete
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(equals("oo-iptables-port-proxy removeproxy 1")).once
    proxy.system_proxy_delete(1)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(equals("oo-iptables-port-proxy removeproxy 1 2 3")).once
    proxy.system_proxy_delete(1, 2, 3)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(regexp_matches(/^oo-iptables-port-proxy/)).never
    assert_equal [nil,nil,0], proxy.system_proxy_delete()
  end

  # Verify the command line constructed by the system proxy add command
  # given a variety of arguments.
  def test_system_proxy_add
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(equals('oo-iptables-port-proxy addproxy 3000 "127.0.0.1:1000"')).once
    proxy.system_proxy_set({:proxy_port => 3000, :addr => '127.0.0.1:1000'})

    OpenShift::Runtime::Utils.expects(:oo_spawn)
      .with(equals('oo-iptables-port-proxy addproxy 3000 "127.0.0.1:1000" 3001 "127.0.0.1:1001" 3002 "127.0.0.1:1002"'))
      .once

    proxy.system_proxy_set(
      {:proxy_port => 3000, :addr => '127.0.0.1:1000'},
      {:proxy_port => 3001, :addr => '127.0.0.1:1001'},
      {:proxy_port => 3002, :addr => '127.0.0.1:1002'}
      )

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(regexp_matches(/^oo-iptables-port-proxy/)).never
    assert_equal [nil,nil,0], proxy.system_proxy_set()
  end

  # Verify the command line constructed by the system proxy show
  # given a variety of arguments.
  def test_system_proxy_show
    proxy = OpenShift::Runtime::FrontendProxyServer.new

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(regexp_matches(/^oo-iptables-port-proxy showproxy 3000 /)).once.returns("127.0.0.1:1234")
    assert_equal "127.0.0.1:1234", proxy.system_proxy_show(3000)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(regexp_matches(/^oo-iptables-port-proxy showproxy 3000 /)).once.returns("")
    assert_nil proxy.system_proxy_show(3000)

    OpenShift::Runtime::Utils.expects(:oo_spawn).with(regexp_matches(/^oo-iptables-port-proxy showproxy/)).never

    err = assert_raises RuntimeError do
      proxy.system_proxy_show(nil)
    end
    assert_equal "No proxy port specified", err.message
  end
end
