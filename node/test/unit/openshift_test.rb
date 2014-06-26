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

require_relative '../coverage_helper'

require 'rubygems'
require 'test/unit'
require 'mocha/setup'
require 'logger'
require 'securerandom'
require 'digest/sha1'

# setup testing module/class hierarchy.
#
# @note This class mimics methods from TestCase when static methods are called
module MCollective
  module Agent
    ;
  end

  module RPC
    class Agent
      def self.activate_when
        raise MiniTest::Assertion, 'activate_when requires a block' unless block_given?
        yield
      end

      def validate(smth, validator)
        true
      end

      def reply
        Hash.new
      end

      def request
        Hash.new
      end

      def meta
        {timeout: 300}
      end

      def report_exception(reference_id, uuid, exception)

      end
    end
  end

  module Util
    ;
  end
end

# Now we can bring in the code to test...
require_relative '../../../plugins/msg-node/mcollective/src/openshift'

# Start your engines!
class OpenshiftTest < MiniTest::Unit::TestCase

  # We only need one agent for all tests
  def before_setup
    @agent = MCollective::Agent::Openshift.new

    if MCollective::Agent::Openshift.const_defined?(:Log)
      MCollective::Agent::Openshift.send(:remove_const, :Log)
    end

    log  = stub()
    info = stub()
    info.stubs(:info).with(instance_of(String)).returns(nil)
    log.stubs(:instance).returns(stub(:info, info))

    MCollective::Agent::Openshift.const_set(:Log, log)

    @agent.startup_hook

    [:@@config, :@@selinux, :@@cartridge_repository, :@@hourglass_timeout].each do |variable|
      assert MCollective::Agent::Openshift.class_variable_defined?(variable), %Q(Class variable #{variable} not defined)
      refute_nil MCollective::Agent::Openshift.class_variable_get(variable)
    end
  end

  def test_echo_action
    @agent.echo_action
  end

  def test_get_facts_action
    MCollective::Util.stubs(:get_fact).with('ip_addr').returns('127.0.0.1')

    contents          = Hash.new
    contents[:output] = Hash.new

    reply = mock('reply')
    reply.expects(:[]=).with(:output, instance_of(Hash)).returns(contents)
    reply.expects(:[]).with(:output).returns(contents[:output])
    @agent.expects(:reply).returns(reply).twice

    request = mock('request')
    request.expects(:[]).with(:facts).returns %w[ip_addr]
    @agent.expects(:request).returns(request)

    @agent.get_facts_action
    assert_equal('127.0.0.1', contents[:output][:ip_addr])
  end

  def test_cartridge_do_action
    contents = Hash.new

    reply = mock('reply')
    reply.expects(:[]=).with(:exitcode, 0).returns(contents)
    reply.expects(:[]=).with(:output, 'test output').returns(contents)
    reply.expects(:[]=).with(:addtl_params, any_parameters).returns(contents)
    @agent.expects(:reply).returns(reply).times(3)

    request = mock('request')
    request.expects(:[]).with(:action).returns 'test_agent'
    request.expects(:[]).with(:args).returns {}
    request.expects(:[]=).with(:args, {}).returns {}
    request.expects(:uniqid).returns(SecureRandom.uuid.gsub('-', ''))
    @agent.expects(:request).returns(request).times(3)

    @agent.expects(:execute_action).
        with('test_agent', any_parameters).
        returns [0, 'test output', nil]
    @agent.cartridge_do_action
  end

  def test_cartridge_do_action_quota
    contents        = Hash.new
    contents[:args] = {'--with-container-uuid' => 'uuid',
                       '--with-app-name'       => 'OpenshiftTest',
    }

    reply = mock('reply')
    reply.expects(:[]=).with(:exitcode, 222).returns(contents[:exitcode] = 222)
    reply.expects(:[]=).with(:output, 'test output').returns('test output')
    reply.expects(:[]=).with(:addtl_params, any_parameters).returns('')
    reply.expects(:fail!).with(instance_of(String))
    @agent.expects(:reply).returns(reply).times(4)

    request = mock('request')
    request.expects(:[]).with(:action).returns 'test_agent'
    request.expects(:[]).with(:args).returns contents[:args]
    request.expects(:uniqid).returns(SecureRandom.uuid.gsub('-', ''))
    @agent.expects(:request).returns(request).times(3)

    @agent.expects(:execute_action).with('test_agent', any_parameters).returns [0, 'test output', nil]
    @agent.expects(:report_quota).with(instance_of(String), 'uuid')
    @agent.expects(:report_resource).with(instance_of(String), 'OpenshiftTest').returns true

    @agent.cartridge_do_action

    assert_equal(222, contents[:exitcode])
  end

  def test_execute_action
    @agent.class.send(:define_method, :oo_test_openshift) { |args| return [0, 'test output', nil] }

    exitcode, output, addtl_params = @agent.execute_action('test-openshift', {})

    assert_equal(0, exitcode)
    assert_equal('test output', output)
    assert_nil addtl_params

    @agent.class.send(:remove_method, :oo_test_openshift)
  end

  def test_execute_action_unsupported
    exitcode, output, addtl_params = @agent.execute_action('test-openshift', {})

    assert_equal(127, exitcode)
    assert_equal('Unsupported action: test-openshift/oo_test_openshift', output)
    assert_nil addtl_params
  end

  def test_execute_exception
    @agent.class.send(:define_method, :oo_test_openshift) { |args| raise 'unit test exception' }

    @agent.expects(:report_exception).with('deadbeef', 'a55aa55a', kind_of(RuntimeError))

    exitcode, output, addtl_params = @agent.execute_action('test-openshift',
                                                           {'--with-reference-id' => 'deadbeef',
                                                           '--with-container-uuid' => 'a55aa55a'
                                                           })
    assert_equal(127, exitcode)
    assert_match(/^An internal exception occurred processing action test-openshift:.*/, output)
    assert_nil addtl_params
    @agent.class.send(:remove_method, :oo_test_openshift)
  end

  def test_execute_parallel_action
    contents = Hash.new
    joblist  = [{job: {action: 'test-openshift', args: {arg1: true}}}]

    config = mock('config')
    config.expects(:identity).returns('aa')
    @agent.expects(:config).returns(config)

    request = mock('request')
    request.expects(:[]).with('aa').returns(joblist)
    @agent.expects(:request).returns(request)

    reply_contents = [{
                          job:                 {action: 'test-openshift', args: {arg1: true}},
                          result_exit_code:    0,
                          result_stdout:       'test output',
                          result_addtl_params: nil
                      }]
    reply          = mock('reply')
    reply.expects(:[]=).with(:exitcode, 0).returns(contents[:exitcode] = 0)
    reply.expects(:[]=).with(:output, reply_contents).returns(reply_contents)
    @agent.expects(:reply).returns(reply).twice

    @agent.expects(:execute_action).with('test-openshift', any_parameters).returns([0, 'test output', nil])
    @agent.execute_parallel_action
  end

  def test_get_app_container_from_args
    args                          = Hash.new
    args['--with-app-uuid']       = SecureRandom.uuid.gsub('-', '')
    args['--with-app-name']       = 'Test Application Name'
    args['--with-container-uuid'] = SecureRandom.uuid.gsub('-', '')
    args['--with-container-name'] = 'Test Container'
    args['--with-namespace']      = 'testdomain'
    args['--with-quota-blocks']   = 15
    args['--with-quota-files']    = 20
    args['--with-uid']            = 1000
    args['--with-hourglass']      = 'HourGlass'

    OpenShift::Runtime::ApplicationContainer.expects(:new).with(
        args['--with-app-uuid'], args['--with-container-uuid'], 1000, 'Test Application Name', 'Test Container',
        'testdomain', 15, 20, 'HourGlass'
    )
    @agent.get_app_container_from_args(args)
  end
end
