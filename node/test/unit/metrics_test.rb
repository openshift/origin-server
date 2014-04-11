#!/usr/bin/env oo-ruby
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
require 'fileutils'

MetricsLineProcessor = OpenShift::Runtime::ApplicationContainerExt::Metrics::MetricsLineProcessor
BufferedLineParser = OpenShift::Runtime::ApplicationContainerExt::Metrics::BufferedLineParser

class OutputCapturer
  def self.capture_stdout(&block)
    old = $stdout
    $stdout = fake = StringIO.new
    block.call
    fake.string
  ensure
    $stdout = old
  end
end

class MetricsLineProcessorTest < OpenShift::NodeTestCase
  def setup
    @container = mock()
    @container.expects(:metrics_metadata).returns({'key1' => 'var1', 'key2' => 'var2'})
    @container.expects(:container_dir).returns('foo')

    ::OpenShift::Runtime::Utils::Environ::expects(:for_gear).with('foo').returns({'var1' => 'value1', 'var2' => 'value2'})
  end

  def test_process_without_cartridge
    @p = MetricsLineProcessor.new(@container)
    output = OutputCapturer.capture_stdout { @p.process('message') }
    assert_equal "type=metric key1=value1 key2=value2 message\n", output
  end

  def test_process_with_cartridge
    cart = mock()
    cart.expects(:name).returns('foo')
    @p = MetricsLineProcessor.new(@container)
    @p.cartridge = cart

    output = OutputCapturer.capture_stdout { @p.process('message') }
    assert_equal "type=metric cart=foo key1=value1 key2=value2 message\n", output
  end

  def test_process_with_cartridge_in_constructor
    cart = mock()
    cart.expects(:name).returns('foo')

    @p = MetricsLineProcessor.new(@container, cart)

    output = OutputCapturer.capture_stdout { @p.process('message') }
    assert_equal "type=metric cart=foo key1=value1 key2=value2 message\n", output
  end
end

class BufferedLineParserTest < OpenShift::NodeTestCase
  def setup
    @line_handler = mock()
  end

  def test_long_line_discarded_single_input
    @line_handler.expects(:process).never
    p = BufferedLineParser.new(5, @line_handler)
    p << 'x' * 6
  end

  def test_discard
    @line_handler.expects(:process).with('d')
    p = BufferedLineParser.new(5, @line_handler)
    p << 'x' * 5
    p << "a\nd\n"
  end

  def test_one_full_line
    @line_handler.expects(:process).with('12345')
    p = BufferedLineParser.new(6, @line_handler)
    p << "12345\n"
  end

  def test_multiple_lines_in_one_input
    @line_handler.expects(:process).with('12345')
    @line_handler.expects(:process).with('abcde')
    p = BufferedLineParser.new(12, @line_handler)
    p << "12345\nabcde\n"
  end

  def test_multiple_lines_in_multiple_inputs
    @line_handler.expects(:process).with('12345')
    @line_handler.expects(:process).with('abcde')
    p = BufferedLineParser.new(12, @line_handler)
    p << "123"
    p << "4"
    p << "5\nab"
    p << "cde"
    p << "\n"
  end
end

class MetricsTest < OpenShift::NodeTestCase
  def setup
    # Set up the container
    @gear_uuid = "5502"
    @user_uid  = "5502"
    @app_name  = 'DeploymentsTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"
    @test_dir = "#{Dir.mktmpdir}/"

    Etc.stubs(:getpwnam).returns(
      OpenStruct.new(
        uid: @user_uid.to_i,
        gid: @user_uid.to_i,
        gecos: "OpenShift guest",
        dir: @test_dir
      )
    )

    @config.stubs(:get).with('METRICS_PER_GEAR_TIMEOUT').returns(3)
    @config.stubs(:get).with('METRICS_PER_SCRIPT_TIMEOUT').returns(1)
    @config.stubs(:get).with('METRICS_MAX_LINE_LENGTH').returns(2000)

    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid, @app_name, @gear_uuid, @namespace, nil, nil, nil)
  end

  def test_no_metrics
    output = OutputCapturer.capture_stdout do
      @container.metrics
    end

    assert_equal '', output
  end

  def test_gear_timeout
    # set the timeout really low
    timeout = 0.0001
    @config.stubs(:get).with('METRICS_PER_GEAR_TIMEOUT').returns(timeout)

    begin
      # fake cartridge_metrics to run for a long time
      @container.class.send(:alias_method, :orig_cartridge_metrics, :cartridge_metrics)
      @container.class.send(:define_method, :cartridge_metrics) { |*args| sleep 0.1 }


      # run the method under test
      err = OutputCapturer.capture_stdout { @container.metrics }

      assert_equal "Gear metrics exceeded timeout of #{timeout}s for gear #{@container.uuid}\n", err
    ensure
      # make sure the hacked method is reverted to its default implementation
      @container.class.send(:alias_method, :cartridge_metrics, :orig_cartridge_metrics)
    end
  end

  def test_cartridge_no_metrics_in_manifest
    cart = mock()
    @container.cartridge_model.expects(:each_cartridge).yields(cart)

    cart.expects(:metrics).returns(nil)
    @container.expects(:run_in_container_context).never

    @container.metrics
  end

  def test_cartridge_no_bin_metrics_file
    cart = mock()
    @container.cartridge_model.expects(:each_cartridge).yields(cart)

    cart.expects(:metrics).returns(1)
    cart.expects(:directory).returns('cart')
    script = PathUtils.join(@container.container_dir, 'cart', 'bin', 'metrics')
    @container.expects(:run_in_container_context).never

    @container.metrics
  end

  def test_cartridge_bin_metrics_file_not_executable
    cart = mock()
    @container.cartridge_model.expects(:each_cartridge).yields(cart)

    cart.expects(:metrics).returns(1)
    cart.expects(:directory).returns('cart')

    bin_dir = PathUtils.join(@container.container_dir, 'cart', 'bin')
    FileUtils.mkdir_p(bin_dir)

    script = PathUtils.join(bin_dir, 'metrics')
    script_file = File.open(script, 'w')
    script_file.close
    @container.expects(:run_in_container_context).never

    @container.metrics
  end

  def test_cartridge_bin_metrics
    cart = mock()
    @container.cartridge_model.expects(:each_cartridge).yields(cart)

    cart.expects(:metrics).returns(1)
    cart.expects(:directory).returns('cart')

    bin_dir = PathUtils.join(@container.container_dir, 'cart', 'bin')
    FileUtils.mkdir_p(bin_dir)

    script = PathUtils.join(bin_dir, 'metrics')
    script_file = File.open(script, 'w', 0755)
    script_file.close
    @container.expects(:run_in_container_context).with(script,
                                                       has_entries(buffer_size: 2000,
                                                                   out: instance_of(BufferedLineParser),
                                                                   timeout: 1.0))

    @container.metrics
  end

  def test_cartridge_bin_metrics_exception
    cart = mock()
    @container.cartridge_model.expects(:each_cartridge).yields(cart)

    cart.expects(:metrics).returns(1)
    cart.expects(:directory).returns('cart')
    cart.expects(:name).returns('cart')

    bin_dir = PathUtils.join(@container.container_dir, 'cart', 'bin')
    FileUtils.mkdir_p(bin_dir)

    script = PathUtils.join(bin_dir, 'metrics')
    script_file = File.open(script, 'w', 0755)
    script_file.close
    @container.expects(:run_in_container_context).with(script,
                                                       has_entries(buffer_size: 2000,
                                                                   out: instance_of(BufferedLineParser),
                                                                   timeout: 1.0))
                                                 .raises(::OpenShift::Runtime::Utils::ShellExecutionException.new('foo'))

    err = OutputCapturer.capture_stdout { @container.metrics }
    assert_equal "Error retrieving metrics for gear #{@container.uuid}, cartridge 'cart': foo\n", err
  end

  def test_app_no_metrics_hook
    metrics_hook = PathUtils.join(@container.container_dir, "app-root", "repo", ".openshift", "action_hooks", "metrics")
    @container.expects(:run_in_container_context).never

    @container.metrics
  end

  def test_app_metrics_hook_not_executable
    action_hooks = PathUtils.join(@container.container_dir, "app-root", "repo", ".openshift", "action_hooks")
    FileUtils.mkdir_p(action_hooks)

    metrics_hook = PathUtils.join(action_hooks, 'metrics')

    metrics_file = File.open(metrics_hook, 'w')
    metrics_file.close

    @container.expects(:run_in_container_context).never

    @container.metrics
  end

  def test_app_bin_metrics
    action_hooks = PathUtils.join(@container.container_dir, "app-root", "repo", ".openshift", "action_hooks")
    FileUtils.mkdir_p(action_hooks)

    metrics_hook = PathUtils.join(action_hooks, 'metrics')

    metrics_file = File.open(metrics_hook, 'w', 0755)
    metrics_file.close

    @container.expects(:run_in_container_context).with(metrics_hook,
                                                       has_entries(buffer_size: 2000,
                                                                   out: instance_of(BufferedLineParser),
                                                                   timeout: 1.0))

    @container.metrics
  end

  def test_app_bin_metrics_exception
    action_hooks = PathUtils.join(@container.container_dir, "app-root", "repo", ".openshift", "action_hooks")
    FileUtils.mkdir_p(action_hooks)

    metrics_hook = PathUtils.join(action_hooks, 'metrics')

    metrics_file = File.open(metrics_hook, 'w', 0755)
    metrics_file.close

    @container.expects(:run_in_container_context).with(metrics_hook,
                                                       has_entries(buffer_size: 2000,
                                                                   out: instance_of(BufferedLineParser),
                                                                   timeout: 1.0))
                                                 .raises(::OpenShift::Runtime::Utils::ShellExecutionException.new('foo'))

    err = OutputCapturer.capture_stdout { @container.metrics }

    assert_equal "Error retrieving application metrics for gear #{@container.uuid}: foo\n", err
  end
end
