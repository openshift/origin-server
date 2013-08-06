require 'openshift-origin-common/utils/path_utils'

require_relative 'selinux'

module OpenShift
  module Runtime
    module Utils
      class UpgradeProgress
        attr_reader :gear_home, :gear_base_dir, :uuid, :steps, :buffer

        def initialize(gear_base_dir, gear_home, uuid)
          @gear_base_dir = gear_base_dir
          @gear_home = gear_home
          @uuid = uuid
          @buffer = []
          @steps = {}
        end

        def step(name)
          unless @steps.has_key?(name)
            @steps[name] = {
              :status => complete?(name) ? :complete : :incomplete,
              :errors => [],
              :context => {}
            }
          end

          step = @steps[name]

          if incomplete?(name)
            begin
              yield(step[:context], step[:errors])
            rescue OpenShift::Runtime::Utils::ShellExecutionException => e
              step[:errors] << "Unhandled shell exception performing step: #{e.message}\nreturn code: #{e.rc}\nstdout: #{e.stdout}\nstderr: #{e.stderr}"
              raise e
            rescue => e
              step[:errors] << "Unhandled exception performing step: #{e.message}\n#{e.backtrace.join("\n")}"
              raise e
            end

            if not step[:errors].empty?
              raise "Errors encountered executing step #{name}"
            end

            mark_complete(name)
          end
        end

        def incomplete?(marker)
          not complete?(marker)
        end

        def complete?(marker)
          File.exists?(marker_path(marker))
        end

        def mark_complete(marker)
          IO.write(marker_path(marker), '')
          log "Marking step #{marker} complete"
          @steps[marker][:status] = :complete
        end

        def done
          globs = %w(.upgrade_complete*)

          globs.each do |glob|
            Dir.glob(File.join(gear_home, 'app-root', 'runtime', glob)).each do |entry|
              FileUtils.rm_f(entry)
            end
          end
        end

        def marker_path(marker)
          File.join(gear_home, 'app-root', 'runtime', ".upgrade_complete_#{marker}")
        end

        def log(message)
          @buffer << message
          message
        end

        def report
          @buffer.join("\n")
        end
      end
    end
  end
end