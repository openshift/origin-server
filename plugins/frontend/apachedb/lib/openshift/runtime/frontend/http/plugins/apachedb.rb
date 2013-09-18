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

require 'rubygems'
require 'active_support/core_ext/class/attribute'
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'fcntl'
require 'json'
require 'tmpdir'

# The mutexes for ApacheDB get declared early and in globals to ensure
# the right mutex is in the right place during threaded operations.
$OpenShift_ApacheDB_Lock = Mutex.new
$OpenShift_GearDB_Lock = Mutex.new

module OpenShift
  module Runtime
    module Frontend
      module Http

        module Plugins

          # Reload the Apache configuration
          def self.reload_httpd(async=false)
            async_opt="-b" if async
            begin
              ::OpenShift::Runtime::Utils::oo_spawn("/usr/sbin/oo-httpd-singular #{async_opt} graceful", :expected_exitstatus=> 0)
            rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
              NodeLogger.logger.error("ERROR: failure from oo-httpd-singular(#{e.rc}): #{@container_uuid}: stdout: #{e.stdout} stderr:#{e.stderr}")
            end
          end

          # Present an API to Apache's DB files for mod_rewrite.
          #
          # The process to update database files is complicated and
          # hand-editing is strongly discouraged for the following reasons:
          #
          # 1. There did not appear to be a corruption free database format in
          # common between ruby and Apache that had a guaranteed consistent
          # API.  Even BerkeleyDB and the BDB module corrupted each other on
          # testing.
          #
          # 2. Every effort was made to ensure that a crash, even due to a
          # system issue such as disk space or memory starvation did not
          # result in a corrupt database and the loss of old information.
          #
          # 3. Every effort was made to ensure that multiple threads and
          # processes could not corrupt or step on each other.
          #
          # 4. While the httxt2dbm tool can run on an existing database, that
          # will result in additions but not removals from the database.  Only
          # some of your changes will take unless the entire db is recreated
          # each time.
          #
          # 5. In order for BerkeleyDB to be safe for multiple processes to
          # access/edit, the environment must be specifically set up to allow
          # locking.  An audit of the Apache source code shows that it does
          # not do that.  And an strace of Apache shows no attempt to either
          # lock or establish a mutex on the BerkeleyDB file.  I believe the
          # claim that BerkeleyDB is safe to have multiple processess
          # reading/writing it is simply not true the way its used by Apache.
          #
          #
          # This locks down to one thread for safety.  You MUST ensure that
          # close is called to release all locks.  Close also syncs changes to
          # Apache if data was modified.
          #
          class ApacheDB < Hash
            READER  = Fcntl::O_RDONLY
            WRITER  = Fcntl::O_RDWR
            WRCREAT = Fcntl::O_RDWR | Fcntl::O_CREAT
            NEWDB   = Fcntl::O_RDWR | Fcntl::O_CREAT | Fcntl::O_TRUNC

            class_attribute :LOCK
            self.LOCK = $OpenShift_ApacheDB_Lock

            class_attribute :LOCKFILEBASE
            self.LOCKFILEBASE = "/var/run/openshift/ApacheDB"

            class_attribute :MAPNAME
            self.MAPNAME = nil

            class_attribute :SUFFIX
            self.SUFFIX = ".txt"

            def initialize(flags=nil)
              @closed = false

              if self.MAPNAME.nil?
                raise NotImplementedError.new("Must subclass with proper map name.")
              end

              @config = ::OpenShift::Config.new
              @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")
              @mode = 0640

              if flags.nil?
                @flags = READER
              else
                @flags = flags
              end

              @filename = PathUtils.join(@basedir, self.MAPNAME)

              @lockfile = self.LOCKFILEBASE + '.' + self.MAPNAME + self.SUFFIX + '.lock'

              super()

              # Each filename needs its own mutex and lockfile
              self.LOCK.lock

              begin
                @lfd = File.new(@lockfile, Fcntl::O_RDWR | Fcntl::O_CREAT, 0640)

                @lfd.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
                if writable?
                  @lfd.flock(File::LOCK_EX)
                else
                  @lfd.flock(File::LOCK_SH)
                end

                if @flags != NEWDB
                  reload
                end

              rescue
                begin
                  if not @lfd.nil?
                    @lfd.close()
                  end
                ensure
                  self.LOCK.unlock
                end
                raise
              end

            end

            def decode_contents(f)
              f.each do |l|
                path, dest = l.strip.split
                if (not path.nil?) and (not dest.nil?)
                  self.store(path, dest)
                end
              end
            end

            def encode_contents(f)
              self.each do |k, v|
                f.write([k, v].join(' ') + "\n")
              end
            end

            def reload
              begin
                File.open(@filename + self.SUFFIX, Fcntl::O_RDONLY) do |f|
                  decode_contents(f)
                end
              rescue Errno::ENOENT
                if not [WRCREAT, NEWDB].include?(@flags)
                  raise
                end
              end
            end

            def writable?
              [WRITER, WRCREAT, NEWDB].include?(@flags)
            end

            def callout
              # Use Berkeley DB so that there's no race condition between
              # multiple file moves.  The Berkeley DB implementation creates a
              # scratch working file under certain circumstances.  Use a
              # scratch dir to protect it.
              Dir.mktmpdir([File.basename(@filename) + ".db-", ""], File.dirname(@filename)) do |wd|
                tmpdb = PathUtils.join(wd, 'new.db')

                httxt2dbm = ["/usr/bin","/usr/sbin","/bin","/sbin"].map {|d| PathUtils.join(d, "httxt2dbm")}.select {|p| File.exists?(p)}.pop
                if httxt2dbm.nil?
                  httxt2dbm="httxt2dbm"
                end

                cmd = %{#{httxt2dbm} -f DB -i #{@filename}#{self.SUFFIX} -o #{tmpdb}}
                begin
                  ::OpenShift::Runtime::Utils::oo_spawn(cmd, :expected_exitstatus=> 0)
                  begin
                    oldstat = File.stat(@filename + '.db')
                    File.chown(oldstat.uid, oldstat.gid, tmpdb)
                    File.chmod(oldstat.mode & 0777, tmpdb)
                  rescue Errno::ENOENT
                  end
                  FileUtils.mv(tmpdb, @filename + '.db', :force=>true)
                rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
                  NodeLogger.logger.error("ERROR: failure httxt2dbm #{@filename}: #{e.rc}: stdout: #{e.stdout} stderr:#{e.stderr}")
                end
              end
            end

            def flush
              if writable?
                File.open(@filename + self.SUFFIX + '-', Fcntl::O_RDWR | Fcntl::O_CREAT | Fcntl::O_TRUNC, 0640) do |f|
                  encode_contents(f)
                  f.fsync
                end

                # Ruby 1.9 Hash preserves order, compare files to see if anything changed
                if FileUtils.compare_file(@filename + self.SUFFIX + '-', @filename + self.SUFFIX)
                  FileUtils.rm(@filename + self.SUFFIX + '-', :force=>true)
                else
                  begin
                    oldstat = File.stat(@filename + self.SUFFIX)
                    FileUtils.chown(oldstat.uid, oldstat.gid, @filename + self.SUFFIX + '-')
                    FileUtils.chmod(oldstat.mode & 0777, @filename + self.SUFFIX + '-')
                  rescue Errno::ENOENT
                  end
                  FileUtils.mv(@filename + self.SUFFIX + '-', @filename + self.SUFFIX, :force=>true)
                  callout
                end
              end
            end

            def close
              @closed=true
              begin
                begin
                  self.flush
                ensure
                  @lfd.close() unless @lfd.closed?
                end
              ensure
                self.LOCK.unlock if self.LOCK.locked?
              end
            end

            def closed?
              @closed
            end

            # Preferred method of access is to feed a block to open so we can
            # guarantee the close.
            def self.open(flags=nil)
              inst = new(flags)
              if block_given?
                begin
                  return yield(inst)
                rescue
                  @flags = nil # Disable flush
                  raise
                ensure
                  if not inst.closed?
                    inst.close
                  end
                end
              end
              inst
            end

          end

          # Manage the nodejs route file via the same API as Apache
          class ApacheDBJSON < ApacheDB
            self.SUFFIX = ".json"

            def decode_contents(f)
              begin
                self.replace(JSON.load(f))
              rescue TypeError, JSON::ParserError
              end
            end

            def encode_contents(f)
              f.write(JSON.pretty_generate(self.to_hash))
            end

            def callout
            end
          end

          #
          # The GearDBPlugin class is used to store a quick lookup
          # table for uuid => fqdn.  At least one plugin must define
          # the "lookup" and "all" functions.
          #
          class GearDBPlugin < PluginBaseClass
            def create
              GearDB.open(GearDB::WRCREAT) do |d|
                d.store(@container_uuid, {
                          'fqdn' => @fqdn,
                          'container_name' => @container_name,
                          'namespace' => @namespace
                        })
              end
            end

            def destroy
              GearDB.open(GearDB::WRCREAT) { |d| d.delete(@container_uuid) }
            end

            def self.lookup_by_uuid(container_uuid)
              GearDB.open(GearDB::READER) do |d|
                config = d[container_uuid]
                if config
                  return self.new(container_uuid, config["fqdn"], config["container_name"], config["namespace"])
                end
              end
              nil
            end

            def self.lookup_by_fqdn(fqdn)
              GearDB.open(GearDB::READER) do |d|
                d.select { |k,v| v["fqdn"] == fqdn }.each do |k,v|
                  return self.new(k, v["fqdn"], v["container_name"], v["namespace"])
                end
              end
              nil
            end

            def self.all
              Enumerator.new do |yielder|
                GearDB.open(GearDB::READER) do |d|
                  d.each do |uuid, config|
                    c = self.new(uuid, config["fqdn"], config["container_name"], config["namespace"])
                    yielder.yield(c)
                  end
                end
              end
            end

          end

          class GearDB < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBJSON
            self.MAPNAME = "geardb"
            self.LOCK = $OpenShift_GearDB_Lock
          end

        end
      end
    end
  end
end
