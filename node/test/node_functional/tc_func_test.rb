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
require_relative '../test_helper'
require 'openshift-origin-node/model/node'
require 'securerandom'

module OpenShift
  module Runtime
    # NOTE: Unfortunately because tc.rb was directly ported from the original shell
    # script for OpenShift it does not lend itself well to mocking the
    # configuration.  There was just too much happening in constructors to
    # effectively mock everything that was required without making the test
    # useless.  These test actually relies on the system configuration.
    class NodeTestTrafficControl < OpenShift::NodeBareTestCase

      def before_setup
        super
        @uuid = SecureRandom.uuid.gsub(/-/, '')
        @uid = 6000
        @secret_token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256)).to_s

        begin
          %x(userdel -f #{Etc.getpwuid(@uid).name})
        rescue ArgumentError
        end

        @container = Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "NodeFunctionalTest",
                                                       "NodeFunctionalTest", "functional-test")
        @container.create(@secret_token)
      end

      def after_teardown
        @container.destroy
      end

      # NOTE: This output will have to be maintained whenever the defaults for
      # and environment are changed.  However, previously there were no tests
      # for traffic control and now that we're making it configurable we need
      # to verify the code executes the way we expect.
      def test_tc_filters
        expected_output = <<TC
filter protocol ip pref 10 u32 
filter protocol ip pref 10 u32 fh 800: ht divisor 1 
filter protocol ip pref 10 u32 fh 800::800 order 2048 key ht 800 bkt 0 flowid 1770:2 
  match sport 587
filter protocol ip pref 10 u32 fh 800::801 order 2049 key ht 800 bkt 0 flowid 1770:3 
  match sport 25
filter protocol ip pref 10 u32 fh 800::802 order 2050 key ht 800 bkt 0 flowid 1770:3 
  match sport 465
TC
        tc_output = %x{tc -p filter show dev eth0 parent #{@uid.to_s(16)}:}
        assert_equal expected_output, tc_output
      end
    end
  end
end
