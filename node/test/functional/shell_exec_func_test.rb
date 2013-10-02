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

module OpenShift
  class UtilsSpawnFunctionalTest < NodeTestCase

    def setup
      @uid     = 5999
      # Using /var/lib/openshift and creating a directory that won't
      # be found by the regular check scripts since using /tmp and
      # /var/tmp causes problems with polyinstantiation.
      @homedir = "/var/lib/openshift/.homedir-#{@uid}"
      
      # Origin Pam policies rely on shell to indicate if user is owned
      # by OpenShift or not.
      @shell = "/usr/bin/oo-trap-user"

      FileUtils.rm_r @homedir if File.exist?(@homedir)
      FileUtils.mkdir_p @homedir
      %x{useradd -m -u #@uid -d #@homedir #@uid -s #{@shell} 1>/dev/null 2>&1}
    end

    def teardown
      %x{userdel #@uid 1>/dev/null}
      %x{rm -rf #@homedir}
    end

    def test_run_as
      skip 'run_as tests require root permissions' if 0 != Process.uid

      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("touch #{Process.pid}.b",
                                    chdir: '/tmp',
                                    uid:   @uid)
      assert_equal 0, rc
      assert_empty err
      assert_empty out
      stats = File.stat(File.join('/tmp', Process.pid.to_s + ".b"))
      assert_equal @uid, stats.uid

      c = File.join(@homedir, Process.pid.to_s + ".c")
      FileUtils.touch c
      stats = File.stat(c)
      assert_equal Process.uid, stats.uid
    end

    def test_run_as_with_error
      skip 'run_as tests require root permissions' if 0 != Process.uid

      _, _, rc = ::OpenShift::Runtime::Utils.oo_spawn("/bin/false",
                                chdir: @homedir,
                                uid:   @uid)
      assert_equal 1, rc
    end

    def test_run_as_with_stderr
      skip 'run_as tests require root permissions' if 0 != Process.uid

      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("/bin/echo 'Good bye, Cruel World' 1>&2; /bin/false",
                                    chdir: @homedir,
                                    uid:   @uid)
      assert_equal 1, rc
      assert_empty out
      assert_equal "Good bye, Cruel World\n", err
    end

    def test_run_as_with_exitstatus
      skip 'run_as tests require root permissions' if 0 != Process.uid

      assert_raise(::OpenShift::Runtime::Utils::ShellExecutionException) do
        ::OpenShift::Runtime::Utils.oo_spawn("/bin/false",
                       chdir:               @homedir,
                       uid:                 @uid,
                       expected_exitstatus: 0)
      end
    end

    def test_run_as_stdout
      skip "run_as tests require root permissions" if 0 != Process.uid

      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("echo Hello, World",
                                    uid: @uid)
      assert_equal 0, rc
      assert_empty err
      assert_equal "Hello, World\n", out
    end

    def test_expected_exitstatus_zero
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn('/bin/true',
                                    chdir:               @homedir,
                                    expected_exitstatus: 0)
      assert_equal 0, rc
      assert_empty err
      assert_empty out
    end

    def test_expected_exitstatus
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn('/bin/false',
                                    chdir:               @homedir,
                                    expected_exitstatus: 1)
      assert_equal 1, rc
      assert_empty err
      assert_empty out
    end

    def test_expected_exception
      assert_raise(::OpenShift::Runtime::Utils::ShellExecutionException) do
        ::OpenShift::Runtime::Utils.oo_spawn('/bin/false',
                       chdir:               @homedir,
                       expected_exitstatus: 0)
      end
    end

    def test_timeout
      assert_raises ::OpenShift::Runtime::Utils::ShellExecutionException do
        ::OpenShift::Runtime::Utils.oo_spawn("sleep 15",
                       timeout: 1)
      end
    end

    def test_stdout
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("echo Hello, World")
      assert_equal 0, rc
      assert_empty err
      assert_equal "Hello, World\n", out
    end

    def test_stderr
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("echo Hello, World 1>&2")
      assert_equal 0, rc
      assert_empty out
      assert_equal "Hello, World\n", err
    end

    def test_chdir
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("touch #{Process.pid}.a",
                                    chdir: @homedir)
      assert_equal 0, rc
      assert_empty err
      assert_empty out

      expected = File.join(@homedir, Process.pid.to_s + '.a')
      assert File.exist?(expected), "#{expected} is missing"
    end

    def test_jailed_env
      refute_empty ENV['HOME']
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn('echo ${HOME}xx',
                                    env:             {},
                                    unsetenv_others: true)
      assert_equal 0, rc
      assert_empty err
      assert_equal "xx\n", out
    end

    def test_env
      refute_empty ENV['HOME']
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn('echo ${HOME}xx')
      assert_equal 0, rc
      assert_empty err
      assert_equal "#{ENV['HOME']}xx\n", out
    end

    def test_run_as_env
      refute_empty ENV['HOME']
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn('echo ${HOME}xx',
                                    uid: @uid)
      assert_equal 0, rc
      assert_empty err
      assert_equal "#{ENV['HOME']}xx\n", out
    end

    def test_streaming_stdout
      msg = %q(Hello, World)
      StringIO.open("w") { |fd|
        out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("echo -n #{msg}",
                                      out:                 fd,
                                      expected_exitstatus: 0)
        assert_equal msg, out.string
        assert_equal 0, err.size
        assert_equal 0, rc
      }
    end

    def test_streaming_stderr
      msg = %q(Goodbye, Cruel World)
      StringIO.open("w") { |fd|
        out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("echo -n #{msg} 1>&2",
                                      err:                 fd,
                                      expected_exitstatus: 0)
        assert_equal 0, out.size
        assert_equal msg, err.string
        assert_equal 0, rc
      }
    end

    def test_streaming_stdin
      msg = %q(Hello, World)

      # StringIO is insufficient for stdin according to Kernel.spawn...
      IO.write("/tmp/#{Process.pid}", msg, 0)
      File.open("/tmp/#{Process.pid}", "r") { |stdin|
        StringIO.open("w") { |stdout|
          out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("cat",
                                        in:                  stdin,
                                        out:                 stdout,
                                        expected_exitstatus: 0)
          assert_equal msg, out.string
          assert_equal 0, err.size
          assert_equal 0, rc
        }
      }
    end

    def test_streaming
      out, err, rc = ::OpenShift::Runtime::Utils.oo_spawn("ls /tmp",
                                    in:                  STDIN,
                                    out:                 STDOUT,
                                    err:                 STDERR,
                                    timeout:             1,
                                    expected_exitstatus: 0)
      assert true, "not sure what to test other than we didn't blow up"
    end
  end
end
