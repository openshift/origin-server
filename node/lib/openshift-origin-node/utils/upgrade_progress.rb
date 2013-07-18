require 'openshift-origin-common/utils/path_utils'
require 'sqlite3'
require 'securerandom'

require_relative 'selinux'

module OpenShift
  module Runtime
    module Utils
      class UpgradeProgress
        attr_reader :gear_home, :gear_base_dir, :uuid, :hostname, :version

        module EventType
          EVENT = "EVENT"
          IRREGULAR_EXIT = "IRREGULAR_EXIT"
        end

        def initialize(gear_base_dir, gear_home, uuid, hostname, version)
          @gear_base_dir = gear_base_dir
          @gear_home = gear_home
          @uuid = uuid
          @hostname = hostname
          @version = version
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

          upgrade_db_base_dir = File.join(gear_base_dir, '.upgrades')
          FileUtils.mkdir(upgrade_db_base_dir, mode: 0o640) unless Dir.exists?(upgrade_db_base_dir)

          upgrade_db_path = File.join(upgrade_db_base_dir, "upgrade-#{version}.sqlite")

          if !File.exists?(upgrade_db_path)
            begin
              @db = SQLite3::Database.new upgrade_db_path
              FileUtils.chmod(0o640, upgrade_db_path)

              # Create a database
              rows = @db.execute <<-EOF
                create table event (
                  event_id varchar(36) primary key not null,
                  event_seq integer,
                  gear_uuid text not null,
                  hostname text not null,
                  name text not null,
                  type text check (type in ('EVENT', 'IRREGULAR_EXIT')),
                  timestamp datetime default(strftime('%Y-%m-%d %H:%M:%f', 'NOW')),
                  rc integer,
                  stdout varchar(1024),
                  stderr varchar(1024)
                );
              EOF
            rescue => e
              raise "Failed to initialize upgrade db at #{upgrade_db_path}: #{e.message}"
            end
          else
            begin
              @db = SQLite3::Database.new upgrade_db_path
            rescue => e
              raise "Failed to open existing upgrade db at #{upgrade_db_path}: #{e.message}"
            end
          end
        end

        def add_event(name, event_args = {})
          event = {
            :event_id => SecureRandom.uuid.delete('-'),
            :gear_uuid => uuid,
            :hostname => hostname,
            :name => name,
            :type => event_args[:type] || EventType::EVENT,
            :rc => event_args[:rc],
            :stdout => event_args[:stdout],
            :stderr => event_args[:stderr]
          }

          insert = <<-EOF
            insert into event (event_id,
              event_seq,
              gear_uuid,
              hostname,
              name,
              type,
              rc,
              stdout,
              stderr
            ) values (
              :event_id,
              (select max(ifnull(event_seq, 0)) + 1 from event),
              :gear_uuid,
              :hostname,
              :name,
              :type,
              :rc,
              :stdout,
              :stderr
            )
          EOF

          begin
            @db.execute(insert,
              "event_id" => event[:event_id],
              "gear_uuid" => event[:gear_uuid],
              "hostname" => event[:hostname],
              "name" => event[:name],
              "type" => event[:type].to_s,
              "rc" => event[:rc],
              "stdout" => event[:stdout],
              "stderr" => event[:stderr])
          rescue => e
            @buffer << "Failed to insert sqlite upgrade event: #{e.message}\n#{event.inspect}"
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

        def log(string, event_args = {})
          add_event(string, event_args)

          string = "#{uuid} #{string}"
          if event_args.has_key?(:rc) || event_args.has_key?(:stdout) || event_args.has_key?(:stderr)
            string = "#{string}\nrc: #{event_args[:rc]}\nstdout: #{event_args[:stdout]}\nstderr: #{event_args[:stderr]}"
          end

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