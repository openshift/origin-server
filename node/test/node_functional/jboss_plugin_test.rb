# encoding: utf-8
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
require_relative '../../../node-util/conf/watchman/plugins.d/jboss_plugin'

class JbossPluginTest < OpenShift::NodeBareTestCase
  # Time format => 2012/02/08 17:57:11,034
  TEMPLATE = "%s ERROR [org.apache.catalina.core.ContainerBase.[jboss.web].[default-host].[/].[HelloWorldServlet]] (http--127.0.250.1-8080-1) Servlet.service() for servlet HelloWorldServlet threw exception: java.lang.OutOfMemoryError: Java heap space\n"

  def setup
    @uuid = 'bfc83ec2b49444fba1c657b0462eddb9'
    @testdir = '/tmp/jboss_plugin_test'
    geardir  = "#{@testdir}/#{@uuid}/"
    cartdir  = "#{geardir}cartridge/"
    envdir   = "#{cartdir}env/"
    logsdir  = "#{geardir}app-root/logs/"

    FileUtils.mkdir_p(envdir)
    FileUtils.mkdir_p(logsdir)

    @server_log = "#{logsdir}jbossews.log"

    @gears = mock
    @gears.expects(:each).yields(@uuid)

    @config = mock
    @config.stubs(:get).with('GEAR_BASE_DIR', '/var/lib/openshift').returns(@testdir)

    @nologger = mock
    @restart = mock
  end

  def teardown
    FileUtils.rm_rf(@testdir)
  end

  def test_no_env
    teardown

    @restart.expects(:call).never
    JbossPlugin.new(@config, @nologger, @gears, @restart).
        apply(OpenStruct.new({epoch: DateTime.now, last_run: DateTime.now}))
  end

  def test_no_log
    FileUtils.rm_f(@server_log)

    @restart.expects(:call).never
    JbossPlugin.new(@config, @nologger, @gears, @restart).
        apply(OpenStruct.new({epoch: DateTime.now, last_run: DateTime.now}))
  end

  def test_empty_log
    File.open(@server_log, 'w') do |file|
      file.write('')
    end

    @restart.expects(:call).never
    JbossPlugin.new(@config, @nologger, @gears, @restart).
        apply(OpenStruct.new({epoch: DateTime.now, last_run: DateTime.now}))
  end

  def test_single_entry
    start_time = DateTime.civil(2012, 2, 7, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
    end

    @restart.expects(:call).with(:restart, @uuid).once
    JbossPlugin.new(@config, nil, @gears, @restart).
        apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
  end

  def test_floor
    start_time = DateTime.civil(2012, 2, 8, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/07 17:57:11,034')
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
    end

    @restart.expects(:call).with(:restart, @uuid).once
    JbossPlugin.new(@config, nil, @gears, @restart).
        apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
  end

  def test_ceiling
    start_time = DateTime.civil(2012, 2, 8, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/07 17:57:11,034')
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
      file.write(TEMPLATE % '2012/02/09 17:57:11,034')
    end

    @restart.expects(:call).with(:restart, @uuid).twice
    JbossPlugin.new(@config, nil, @gears, @restart).
        apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
  end

  def test_utf8
    start_time = DateTime.civil(2012, 2, 7, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      # Write something using utf-8
      file.write('2012/02/07 17:57:11,034 INFO  [stdout] (Ergebnisse_Holen) {pointsTeam2=2, matchIsFinished=true, pointsTeam1=0, nameTeam1=Borussia Mönchengladbach, nameTeam2=Bayern München}')
      file.write("\n")
      # Write something using ISO-8859-1 
      file.write("\xe9\n")
    end

    @restart.expects(:call).never
    JbossPlugin.new(@config, nil, @gears, @restart).
        apply(OpenStruct.new({epoch: start_time - 1.minute, last_run: start_time}))
  end
end
