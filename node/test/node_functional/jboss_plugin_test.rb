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

require 'date'
require_relative '../../../node-util/conf/watchman/plugins.d/jboss_plugin'

class JbossPluginTest < OpenShift::NodeBareTestCase
  # Time format => 2012/02/08 17:57:11,034
  TEMPLATE = "%s ERROR [org.apache.catalina.core.ContainerBase.[jboss.web].[default-host].[/].[HelloWorldServlet]] (http--127.0.250.1-8080-1) Servlet.service() for servlet HelloWorldServlet threw exception: java.lang.OutOfMemoryError: Java heap space\n"

  def jboss_name
    %w(JBOSSEAP JBOSSEWS JBOSSAS).sample
  end

  def setup
    @uuid = 'bfc83ec2b49444fba1c657b0462eddb9'

    @testdir = '/tmp/jboss_plugin_test'
    cartdir  = "#{@testdir}/#{@uuid}/cartridge/"
    envdir   = "#{cartdir}env/"
    logsdir  = "#{cartdir}logs/"

    FileUtils.mkdir_p(envdir)
    FileUtils.mkdir_p(logsdir)

    @server_log = "#{logsdir}server.log"
    IO.write("#{envdir}OPENSHIFT_#{jboss_name}_LOG_DIR", logsdir)

    @gears = mock
    @gears.expects(:each).yields(@uuid)

    @config = mock
    @config.stubs(:get).with('GEAR_BASE_DIR', '/var/lib/openshift').returns(@testdir)
  end

  def teardown
    FileUtils.rm_rf(@testdir)
  end

  def test_no_env
    teardown

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    JbossPlugin.new(@config, @gears, restart, DateTime.now).apply

    assert_equal 0, counter, 'Failed to handle missing cartridge'
  end

  def test_no_log
    FileUtils.rm_f(@server_log)

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    JbossPlugin.new(@config, @gears, restart, DateTime.now).apply

    assert_equal 0, counter, 'Failed to handle missing file'
  end

  def test_empty_log
    File.open(@server_log, 'w') do |file|
      file.write('')
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    JbossPlugin.new(@config, @gears, restart, DateTime.now).apply

    assert_equal 0, counter, 'Failed to process empty file'
  end

  def test_single_entry
    start_time = DateTime.civil(2012, 2, 7, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    JbossPlugin.new(@config, @gears, restart, start_time).apply

    assert_equal 1, counter, 'Failed to find single entry'
  end

  def test_floor
    start_time = DateTime.civil(2012, 2, 8, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/07 17:57:11,034')
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
    end

    counter = 0
    restart = lambda { |u, t| counter += 1}
    JbossPlugin.new(@config, @gears, restart, start_time).apply

    assert_equal 1, counter, 'Failed floor test'
  end

  def test_ceiling
    start_time = DateTime.civil(2012, 2, 8, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write(TEMPLATE % '2012/02/07 17:57:11,034')
      file.write(TEMPLATE % '2012/02/08 17:57:11,034')
      file.write(TEMPLATE % '2012/02/09 17:57:11,034')
    end

    counter = 0
    restart = lambda { |u, t| counter += 1 }
    JbossPlugin.new(@config, @gears, restart, start_time).apply

    assert_equal 2, counter, 'Failed to find 2 entries'
  end

  def test_utf8
    start_time = DateTime.civil(2012, 2, 7, 12, 0, 0, -6)
    File.open(@server_log, 'w') do |file|
      file.write('2012/02/07 17:57:11,034 INFO  [stdout] (Ergebnisse_Holen) {pointsTeam2=2, matchIsFinished=true, pointsTeam1=0, nameTeam1=Borussia Mönchengladbach, nameTeam2=Bayern München}')
      file.write("\n")
    end

    restart = lambda { |u, t| raise 'This should never happen!' }
    JbossPlugin.new(@config, @gears, restart, start_time).apply
  end
end