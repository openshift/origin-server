require 'openshift-origin-common/utils/path_utils'
require_relative 'selinux'

module OpenShiftMigration
  class MigrationProgress
    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
      @buffer = []
    end

    def init_store()
      # TODO: use GEAR_BASE_DIR from node config
      data_dir = File.join('/var/lib/openshift', @uuid, %w(app-root data))
      if !File.exists?(data_dir)
        log "Creating data directory #{data_dir} for #{@uuid} because it does not exist"
        FileUtils.mkpath(data_dir)
        FileUtils.chmod_R(0o750, data_dir)
        PathUtils.oo_chown_R(@uuid, @uuid, data_dir)
        mcs_label = OpenShift::Utils::SELinux::get_mcs_label(uuid)
        OpenShift::Utils::SELinux.set_mcs_label_R(mcs_label, data_dir)
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
    end

    def has_instruction?(instruction)
      File.exists?(instruction_path(instruction))
    end

    def set_instruction(instruction)
      FileUtils.touch(instruction_path(instruction))
      log "Creating migration instruction #{instruction}"
    end

    def done
      globs = %w(.migration_complete* .migration_instruction*)

      globs.each do |glob|
        Dir.glob(File.join('/var/lib/openshift', @uuid, 'app-root', 'data', glob)).each do |entry|
          FileUtils.rm_f(entry)
        end
      end
    end

    def marker_path(marker)
      File.join('/var/lib/openshift', @uuid, 'app-root', 'data', ".migration_complete_#{marker}")
    end

    def instruction_path(instruction)
      File.join('/var/lib/openshift', @uuid, 'app-root', 'data', ".migration_instruction_#{instruction}")
    end

    def log(string)
      @buffer << string
      string
    end

    def report
      @buffer.join("\n")
    end
  end
end