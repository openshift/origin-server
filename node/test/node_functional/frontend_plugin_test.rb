#--
# Copyright 2014 Red Hat, Inc.
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

require_relative '../test_helper'

require 'ostruct'
require 'date'
require 'active_support/core_ext/numeric/time'
require_relative '../../../node-util/conf/watchman/plugins.d/frontend_plugin'

class FrontendPluginTest < OpenShift::NodeBareTestCase
  def setup
    @testdir = '/tmp/frontend_plugin_test'
    FileUtils.mkdir_p(@testdir)

    @config = mock
    @config.stubs(:get).with('OPENSHIFT_HTTP_CONF_DIR', '/etc/httpd/conf.d/openshift').returns(@testdir)

    @iteration = OpenStruct.new({epoch: DateTime.now, last_run: DateTime.now})

    @nologger = stub_everything
  end

  def teardown
    FileUtils.rm_rf(@testdir)
  end

  def test_no_delete
    IO.write(File.join(@testdir, 'test_0_dir.conf'), 'this is a test')
    conf_dir = File.join(@testdir, 'test_dir')
    FileUtils.mkdir_p(conf_dir)
    FileUtils.touch(File.join(conf_dir, 'test_file'))

    ::OpenShift::Runtime::Frontend::Http::Plugins.expects(:reload_httpd).never
    FrontendPlugin.new(@config, @nologger, nil, nil).apply(@iteration)

    assert File.exist?(File.join(conf_dir, 'test_file'))
  end

  def test_delete
    FileUtils.touch(File.join(@testdir, 'test_0_dir.conf'), mtime: (Time.now - 7200))
    FileUtils.touch(File.join(@testdir, 'test_0_dir_ha.conf'), mtime: (Time.now - 7200))
    conf_dir = File.join(@testdir, 'test_dir')
    FileUtils.mkdir_p(conf_dir)
    FileUtils.touch(File.join(conf_dir, 'test_file'))

    ::OpenShift::Runtime::Frontend::Http::Plugins.expects(:reload_httpd).once
    FrontendPlugin.new(@config, @nologger, nil, nil).apply(@iteration)

    assert (not File.exist?(File.join(conf_dir, 'test_file'))), 'no files should be in conf directory'
    assert (not File.exist?(File.join(@testdir, 'test_0_dir.conf'))), 'conf file should have been deleted'
  end
end
