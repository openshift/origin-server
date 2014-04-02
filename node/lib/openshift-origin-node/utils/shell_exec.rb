#--
# Copyright 2010-2013 Red Hat, Inc.
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

require 'rubygems'
require 'timeout'
require 'open4'

require_relative '../utils/node_logger'
require_relative 'sanitize'

module OpenShift
  module Runtime
    module Utils
      include NodeLogger

      class ShellExecutionException < Exception
        attr_accessor :rc, :stdout, :stderr

        def initialize(msg, rc=-1, stdout = nil, stderr = nil)
          super msg
          self.rc     = rc
          self.stdout = stdout
          self.stderr = stderr
        end
      end

      # Exception used to signal command overran its timeout in seconds
      class TimeoutExceeded < RuntimeError
        attr_reader :seconds

        # seconds - integer of maximum seconds to wait on command
        def initialize(seconds)
          super 'Timeout exceeded'
          @seconds = seconds
        end

        def to_s
          super + " duration of #@seconds seconds"
        end
      end

      # oo_spawn(command, [, options]) -> [stdout, stderr, exit status]
      #
      # spawn executes specified command and return its stdout, stderr and exit status.
      # Or, raise exceptions if certain conditions are not met.
      #
      # command: command line string which is passed to the standard shell
      #
      # options: hash
      #   :env: hash
      #     name => val : set the environment variable
      #     name => nil : unset the environment variable
      #   :unsetenv_others => true   : clear environment variables except specified by :env
      #   :chdir => path             : set current directory when running command
      #   :expected_exitstatus       : An Integer value for the expected return code of command
      #                              : If not set spawn() returns exitstatus from command otherwise
      #                              : raise an error if exitstatus is not expected_exitstatus
      #   :timeout                   : Maximum number of seconds to wait for command to finish. default: 3600
      #   :uid                       : spawn command as given user in a SELinux context using runuser/runcon,
      #                              : stdin for the command is /dev/null
      #   :out                       : If specified, STDOUT from the child process will be redirected to the
      #                                provided +IO+ object.
      #   :err                       : If specified, STDERR from the child process will be redirected to the
      #                                provided +IO+ object.
      #   :quiet                     : If specified, the output from the command will not be logged
      #
      # NOTE: If the +out+ or +err+ options are specified, the corresponding return value from +oo_spawn+
      # will be the incoming/provided +IO+ objects instead of the buffered +String+ output. It's the
      # responsibility of the caller to correctly handle the resulting data type.
      def self.oo_spawn(command, options = {})

        options[:env]         ||= (options[:env] || {})
        options[:timeout]     ||= 3600
        options[:buffer_size] ||= 32768

        opts                   = {}
        opts[:unsetenv_others] = (options[:unsetenv_others] || false)
        opts[:close_others]    = true
        opts[:in]              = (options[:in] || '/dev/null')
        opts[:chdir]           = options[:chdir] if options[:chdir]

        IO.pipe do |read_stderr, write_stderr|
          IO.pipe do |read_stdout, write_stdout|
            opts[:out] = write_stdout
            opts[:err] = write_stderr

            if options[:uid]
              # lazy init otherwise we end up with a cyclic require...
              require 'openshift-origin-node/utils/selinux_context'

              current_context  = SelinuxContext.instance.getcon
              target_context   = SelinuxContext.instance.from_defaults(SelinuxContext.instance.get_mcs_label(options[:uid]))

              # Only switch contexts if necessary
              if (current_context != target_context) || (Process.uid != options[:uid])
                target_name = Etc.getpwuid(options[:uid]).name
                exec        = %Q{exec /usr/bin/runcon '#{target_context}' /bin/sh -c \\"#{command}\\"}
                command     = %Q{/sbin/runuser -s /bin/sh #{target_name} -c "#{exec}"}
              end
            end

            NodeLogger.logger.trace { "oo_spawn running #{command}: #{opts}" }
            pid = Kernel.spawn(options[:env], command, opts)

            unless pid
              raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                        "Kernel.spawn failed for command '#{command}'")
            end

            begin
              write_stdout.close
              write_stderr.close

              out, err, status = read_results(pid, read_stdout, read_stderr, options)
              NodeLogger.logger.debug { "Shell command '#{command}' ran. rc=#{status.exitstatus} out=#{options[:quiet] ? "[SILENCED]" : Runtime::Utils.sanitize_credentials(out)}" }

              if (!options[:expected_exitstatus].nil?) && (status.exitstatus != options[:expected_exitstatus])
                raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                          "Shell command '#{command}' returned an error. rc=#{status.exitstatus}",
                          status.exitstatus, out, err)
              end

              return [out, err, status.exitstatus]
            rescue TimeoutExceeded => e
              kill_process_tree(pid)
              raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                        "Shell command '#{command}' exceeded timeout of #{e.seconds}", -1, out, err)
            end
          end
        end
      end

      private
      # read_results(stdout pipe, stderr pipe, options) -> [*standard out, *standard error]
      #
      # read stdout and stderr from spawned command until timeout
      #
      # options: hash
      #   :timeout     => seconds to wait for command to finish. Default: 3600
      #   :buffer_size => how many bytes to read from pipe per iteration. Default: 32768
      def self.read_results(pid, stdout, stderr, options)
        # TODO: Are these variables thread safe...?
        out     = (options[:out] || '')
        err     = (options[:err] || '')
        status  = nil
        readers = [stdout, stderr]

        begin
          Timeout::timeout(options[:timeout]) do
            while readers.any?
              ready = IO.select(readers, nil, nil, 10)

              if ready.nil?
                # If there is no IO to process check if child has exited...
                _, status = Process.wait2(pid, Process::WNOHANG)
              else
                # Otherwise, process us some IO...
                ready[0].each do |fd|
                  buffer = (fd == stdout) ? out : err
                  begin
                    partial = fd.readpartial(options[:buffer_size])
                    buffer << partial

                    NodeLogger.logger.trace { "oo_spawn buffer(#{fd.fileno}/#{fd.pid}) #{Runtime::Utils.sanitize_credentials(partial)}" }
                  rescue Errno::EAGAIN, Errno::EINTR
                  rescue EOFError
                    readers.delete(fd)
                    fd.close
                  end
                end
              end
            end

            _, status = Process.wait2 pid
            [out, err, status]
          end
        rescue Timeout::Error
          raise TimeoutExceeded, options[:timeout]
        rescue Errno::ECHILD
          return [out, err, status]
        end
      end

      # kill_process_tree 2199 -> fixnum
      #
      # Given a pid find it and KILL it and all its children
      def self.kill_process_tree(pid)
        ps_results = `ps -e -opid,ppid --no-headers`.split("\n")

        ps_tree = Hash.new { |h, k| h[k] = [k] }
        ps_results.each { |pair|
          p, pp = pair.split(' ')
          ps_tree[pp.to_i] << p.to_i
        }
        Process.kill("KILL", *(ps_tree[pid].flatten))
        Process.detach(pid)
      end
    end
  end
end
