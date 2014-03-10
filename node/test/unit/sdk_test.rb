#!/usr/bin/env oo-ruby
#--
# Copyright 2012-2013 Red Hat, Inc.
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
# Test the OpenShift sdk class
#
require_relative '../test_helper'
require 'openshift-origin-node/model/application_container_ext/ssh_authorized_keys'

include OpenShift::Runtime::ApplicationContainerExt::SecureShell

module OpenShift
  class SdkTest < OpenShift::NodeTestCase
    def test_translate_shell_ex_for_client
      orig = Runtime::Utils::ShellExecutionException.new("Message", 1, "stdout", "stderr")
      orig.set_backtrace(["line1", "line2"])

      translated = Runtime::Utils::Sdk.translate_shell_ex_for_client(orig)

      assert_kind_of Runtime::Utils::ShellExecutionException, translated
      assert_equal orig.message, translated.message
      assert_equal orig.rc, translated.rc
      assert_equal Runtime::Utils::Sdk.translate_out_for_client(orig.stdout, :message), translated.stdout
      assert_equal Runtime::Utils::Sdk.translate_out_for_client(orig.stderr, :error), translated.stderr
      assert_equal orig.backtrace, translated.backtrace
    end

    def test_translate_shell_ex_for_client_rc_override
      orig = Runtime::Utils::ShellExecutionException.new("Message", 1, "stdout", "stderr")
      orig.set_backtrace(["line1", "line2"])

      translated = Runtime::Utils::Sdk.translate_shell_ex_for_client(orig, 2)

      assert_kind_of Runtime::Utils::ShellExecutionException, translated
      assert_equal orig.message, translated.message
      assert_equal 2, translated.rc
      assert_equal Runtime::Utils::Sdk.translate_out_for_client(orig.stdout, :message), translated.stdout
      assert_equal Runtime::Utils::Sdk.translate_out_for_client(orig.stderr, :error), translated.stderr
      assert_equal orig.backtrace, translated.backtrace
    end

    def test_translate_shell_ex_for_client_unsupported_ex_type
      orig = RuntimeError.new
      translated = Runtime::Utils::Sdk.translate_shell_ex_for_client(orig)
      assert_equal orig, translated
    end

    def test_translate_out_for_client_message
      out = "message1\nmessage2\nmessage3\n"

      translated = Runtime::Utils::Sdk.translate_out_for_client(out, :message)

      assert_equal "CLIENT_MESSAGE: message1\nCLIENT_MESSAGE: message2\nCLIENT_MESSAGE: message3\n", translated
    end

    def test_translate_out_for_client_error
      out = "message1\nmessage2\nmessage3\n"

      translated = Runtime::Utils::Sdk.translate_out_for_client(out, :error)

      assert_equal "CLIENT_ERROR: message1\nCLIENT_ERROR: message2\nCLIENT_ERROR: message3\n", translated
    end

    def test_translate_out_for_client_nil
      translated = Runtime::Utils::Sdk.translate_out_for_client(nil, :message)

      assert_equal "", translated
    end

    def test_bash_sdk_version_comparison
      test_path = File.expand_path(File.dirname(__FILE__))
      version_in_range = File.join(test_path, 'helpers', 'test_bash_sdk_version_in_range.sh')

      #test equal segment length out of lower range
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_in_range} '0.0.1' '0.0.11' '0.1.0'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp

      #test different segment lenth ouf of uppper range
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_in_range} '0.2' '0.0.11' '0.1.0'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp

      #test equal seqment length equal to lower bound
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_in_range} '0.0.11' '0.0.11' '0.1.0'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      #test equal segment length equal to upper bound
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_in_range} '0.1.0' '0.0.11' '0.1.0'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      #test test different segment length in range
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_in_range} '0.0.11.1' '0.0.11' '0.1.0'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      version_lt = File.join(test_path, 'helpers', 'test_bash_sdk_version_lt.sh')

      #test different segment length less than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_lt} '0.1' '0.0.11'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp

      #test different segment length less than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_lt} '0.0.11.0' '0.0.11'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp

      #test equal segment length less than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_lt} '0.0.1' '0.0.11'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      version_gt = File.join(test_path, 'helpers', 'test_bash_sdk_version_gt.sh')

      #test equal segment length greater than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_gt} '0.0.111' '0.0.1'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      #test different segment length greater than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_gt} '1' '0.0.1'")
      assert_equal 0, rc
      assert_equal "PASS", out.chomp

      #test different segment length greater than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_gt} '1' '1.0.0'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp

      #test equal segment lenth with no dots greater than
      out,err,rc = ::OpenShift::Runtime::Utils::oo_spawn("#{version_gt} '1' '2'")
      assert_equal 0, rc
      assert_equal "FAIL", out.chomp
    end
  end
end
