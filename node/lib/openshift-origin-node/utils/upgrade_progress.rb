require 'openshift-origin-common/utils/path_utils'
require 'sqlite3'

require_relative 'selinux'

module OpenShift
  module Runtime
    module Utils
      class UpgradeProgress
        attr_reader :gear_home, :gear_base_dir

        def initialize(gear_base_dir, gear_home, uuid)
          @gear_base_dir = gear_base_dir
          @gear_home = gear_home
          @uuid = uuid
          @buffer = []
        end

        def init_store
          runtime_dir = File.join(gear_home, %w(app-root runtime))

          if !File.exists?(runtime_dir)
            log "Creating data directory #{runtime_dir} for #{@gear_home} because it does not exist"
            FileUtils.mkpath(runtime_dir)
            FileUtils.chmod_R(0o750, runtime_dir)
            PathUtils.oo_chown_R(@uuid, @uuid, runtime_dir)
            mcs_label = OpenShift::Runtime::Utils::SELinux::get_mcs_label(uuid)
            OpenShift::Runtime::Utils::SELinux.set_mcs_label_R(mcs_label, runtime_dir)
          end

          upgrade_db_path = File.join(gear_base_dir, '.upgrade_db')

          if !File.exists?(upgrade_db_path)
            @db = SQLite3::Database.new upgrade_db_path

            # Create a database
            rows = @db.execute <<-EOF
              create table event (
                event_id integer primary key asc autoincrement,
                gear_uuid text not null,
                name text not null,
                type text check (type in ('EVENT','TRANS_BEGIN','TRANS_END','IRREGULAR_EXIT')),
                timestamp datetime not null,
                rc integer,
                stdout varchar(1024),
                stderr varchar(1024)
              );
            EOF
          else 
            @db = SQLite3::Database.new upgrade_db_path
          end
        end

        def add_event(name, type = 'EVENT')
          @db.execute("insert into event (gear_uuid, name, type, timestamp) values (?, ?, ?, datetime('now'))", @uuid, name, type)
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
          globs = %w(.upgrade_complete* .upgrade_instruction*)

          globs.each do |glob|
            Dir.glob(File.join(gear_home, 'app-root', 'runtime', glob)).each do |entry|
              FileUtils.rm_f(entry)
            end
          end
        end

        def marker_path(marker)
          File.join(gear_home, 'app-root', 'runtime', ".upgrade_complete_#{marker}")
        end

        def instruction_path(instruction)
          File.join(gear_home, 'app-root', 'runtime', ".upgrade_instruction_#{instruction}")
        end

        def log(string)
          add_event(string)
          @buffer << string
          string
        end

        def report
          @buffer.join("\n")
        end
      end
    end
  end
end