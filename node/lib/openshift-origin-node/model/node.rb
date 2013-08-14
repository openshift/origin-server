#--
# Copyright 2012 Red Hat, Inc.
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

require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-common'
require 'safe_yaml'
require 'etc'

SafeYAML::OPTIONS[:default_mode] = :unsafe

module OpenShift
  module Runtime
    class NodeCommandException < StandardError; end

    class Node < Model
      DEFAULT_PAM_LIMITS_ORDER = 84
      DEFAULT_PAM_LIMITS_DIR   = '/etc/security/limits.d'
      DEFAULT_PAM_LIMITS_VARS  = %w(core data fsize memlock nofile rss stack cpu nproc as maxlogins priority locks sigpending msgqueue nice rprio)
      DEFAULT_PAM_SOFT_VARS    = %w(nproc)

      DEFAULT_QUOTA            = { 'quota_files' => 1000, 'quota_blocks' => 128 * 1024 }
      DEFAULT_PAM_LIMITS       = { 'nproc' => 100 }

      def self.get_cartridge_list(list_descriptors = false, porcelain = false, oo_debug = false)
        carts = []
        CartridgeRepository.instance.latest_versions do |cartridge|
          begin
            print "Loading #{cartridge.name}-#{cartridge.version}..." if oo_debug

            # Deep copy is necessary here because OpenShift::Cartridge makes destructive changes
            # to the hash passed to from_descriptor
            v1_manifest            = Marshal.load(Marshal.dump(cartridge.manifest))
            v1_manifest['Version'] = cartridge.version
            carts.push OpenShift::Cartridge.new.from_descriptor(v1_manifest)
            print "OK\n" if oo_debug
          rescue Exception => e
            print "ERROR\n" if oo_debug
            print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
          end
        end

        print "\n\n\n" if oo_debug

        output = ""
        if porcelain
          if list_descriptors
            output << "CLIENT_RESULT: "
            output << carts.map{|c| c.to_descriptor.to_yaml}.to_json
          else
            output << "CLIENT_RESULT: "
            output << carts.map{|c| c.name}.to_json
          end
        else
          if list_descriptors
            carts.each do |c|
              output << "Cartridge name: #{c.name}\n\nDescriptor:\n #{c.to_descriptor.inspect}\n\n\n"
            end
          else
            output << "Cartridges:\n"
            carts.each do |c|
              output << "\t#{c.name}\n"
            end
          end
        end
        output
      end

      # This won't be updated for v2 because it's going away soon.
      def self.get_cartridge_info(cart_name, porcelain = false, oo_debug = false)
        output = ""
        cart_found = false

        cartridge_path = OpenShift::Config.new.get("CARTRIDGE_BASE_PATH")
        Dir.foreach(cartridge_path) do |cart_dir|
          next if [".", "..", "embedded", "abstract", "abstract-httpd", "haproxy-1.4", "mysql-5.1", "mongodb-2.2", "postgresql-8.4"].include? cart_dir
          path = PathUtils.join(cartridge_path, cart_dir, "info", "manifest.yml")
          begin
            cart = OpenShift::Cartridge.new.from_descriptor(YAML.load(File.open(path), :safe => true))
            if cart.name == cart_name
              output << "CLIENT_RESULT: "
              output << cart.to_descriptor.to_json
              cart_found = true
              break
            end
          rescue Exception => e
            print "ERROR\n" if oo_debug
            print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
          end
        end

        embedded_cartridge_path = PathUtils.join(cartridge_path, "embedded")
        if (! cart_found) and File.directory?(embedded_cartridge_path)
          Dir.foreach(embedded_cartridge_path) do |cart_dir|
            next if [".",".."].include? cart_dir
            path = PathUtils.join(embedded_cartridge_path, cart_dir, "info", "manifest.yml")
            begin
              cart = OpenShift::Cartridge.new.from_descriptor(YAML.load(File.open(path), :safe => true))
              if cart.name == cart_name
                output << "CLIENT_RESULT: "
                output << cart.to_descriptor.to_json
                break
              end
            rescue Exception => e
              print "ERROR\n" if oo_debug
              print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
            end
          end
        end
        output
      end

      def self.get_quota(uuid)
        begin
          Etc.getpwnam(uuid)
        rescue ArgumentError
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Unable to obtain quota user #{uuid} does not exist",
                                                        :error))
        end

        stdout, _, _ = Utils.oo_spawn("quota --always-resolve -w #{uuid}")
        results      = stdout.split("\n").grep(%r(^.*/dev/))
        if results.empty?
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Unable to obtain quota for user #{uuid}",
                                                        :error))
        end

        results = results.first.strip.split(' ')

        {device:      results[0],
         blocks_used: results[1].to_i, blocks_quota: results[2].to_i, blocks_limit: results[3].to_i,
         inodes_used: results[4].to_i, inodes_quota: results[5].to_i, inodes_limit: results[6].to_i
        }
      end

      def self.get_gear_mountpoint
        cartridge_path = OpenShift::Config.new.get("GEAR_BASE_DIR")

        oldpath=File.absolute_path(cartridge_path)
        olddev=File.stat(oldpath).dev
        while true
          newpath = File.dirname(oldpath)
          newdev  = File.stat(newpath).dev
          if (newpath == oldpath) or (newdev != olddev)
            break
          end
          oldpath = newpath
        end
        oldpath
      end

      def self.set_quota(uuid, blocksmax, inodemax)
        current_quota, current_inodes, cur_quota = 0, 0, nil

        begin
          cur_quota = get_quota(uuid)
        rescue NodeCommandException
          # keep defaults
        end

        unless nil == cur_quota
          current_quota  = cur_quota[:blocks_used]
          blocksmax      = cur_quota[:blocks_limit] if blocksmax.to_s.empty?
          current_inodes = cur_quota[:inodes_used]
          inodemax       = cur_quota[:inodes_limit] if inodemax.to_s.empty?
        end

        if current_quota > blocksmax.to_i
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Current usage #{current_quota} exceeds requested quota #{blocksmax}",
                                                        :error))
        end

        if current_inodes > inodemax.to_i
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Current inodes #{current_inodes} exceeds requested inodes #{inodemax}",
                                                        :error))
        end

        mountpoint      = self.get_gear_mountpoint
        cmd             = "setquota --always-resolve -u #{uuid} 0 #{blocksmax} 0 #{inodemax} -a #{mountpoint}"
        _, stderr, rc = Utils.oo_spawn(cmd)
        raise NodeCommandException.new "Error: #{stderr} executing command #{cmd}" unless rc == 0
      end

      def self.init_quota(uuid, blocksmax=nil, inodemax=nil)
        resource = OpenShift::Config.new('/etc/openshift/resource_limits.conf')
        blocksmax = (blocksmax or resource.get('quota_blocks') or DEFAULT_QUOTA['quota_blocks'])
        inodemax  = (inodemax  or resource.get('quota_files')  or DEFAULT_QUOTA['quota_files'])
        self.set_quota(uuid, blocksmax.to_i, inodemax.to_i)
      end

      def self.remove_quota(uuid)
        begin
          self.set_quota(uuid, 0, 0)
        rescue NodeCommandException
          # If the user no longer exists than it has no quota
        end
      end

      def self.find_system_messages(pattern)
        regex = Regexp.new(pattern)
        open('/var/log/messages') { |f| f.grep(regex) }.join("\n")
      end

      def self.init_pam_limits_all
        config = OpenShift::Config.new
        gecos = (config.get("GEAR_GECOS") || "OO application container")

        uuids=[]
        Etc.passwd do |pwent|
          uuids << pwent.name if pwent.gecos == gecos
        end

        uuids.each do |uuid|
          init_pam_limits(uuid)
        end
      end

      def self.init_pam_limits(uuid, limits={})
        resource =OpenShift::Config.new('/etc/openshift/resource_limits.conf')
        limits_order = (resource.get('limits_order') or DEFAULT_PAM_LIMITS_ORDER)
        limits_file = PathUtils.join(DEFAULT_PAM_LIMITS_DIR, "#{limits_order}-#{uuid}.conf")

        DEFAULT_PAM_LIMITS_VARS.each do |k|
          if not limits.has_key?(k)
            v = resource.get("limits_#{k}")
            if not v.nil?
              limits[k]=v
            end
          end
        end

        DEFAULT_PAM_LIMITS.each { |k, v| limits[k]=v unless limits.has_key?(k) }

        File.open(limits_file, File::RDWR | File::CREAT | File::TRUNC ) do |f|
          f.write("# PAM process limits for guest #{uuid}\n")
          f.write("# see limits.conf(5) for details\n")
          f.write("#Each line describes a limit for a user in the form:\n")
          f.write("#\n")
          f.write("#<domain>        <type>  <item>  <value>\n")
          limits.each do |k, v|
            if DEFAULT_PAM_SOFT_VARS.include?(k) and (v.to_i != 0)
              limtype = "soft"
            else
              limtype = "hard"
            end
            f.write("#{uuid}\t#{limtype}\t#{k}\t#{v}\n")
          end
          f.fsync
        end
      end

      def self.get_pam_limits(uuid)
        resource = OpenShift::Config.new('/etc/openshift/resource_limits.conf')
        limits_order = (resource.get('limits_order') or DEFAULT_PAM_LIMITS_ORDER)
        limits_file = PathUtils.join(DEFAULT_PAM_LIMITS_DIR, "#{limits_order}-#{uuid}.conf")

        limits = {}

        begin
          File.open(limits_file, File::RDONLY) do |f|
            f.each do |l|
              l.gsub!(/\#.*$/,'')
              l.strip!
              l.chomp!
              limset = l.split()
              if (limset[0] == uuid) and limset[2] and limset[3]
                limits[limset[2]]=limset[3]
              end
            end
          end
        rescue Errno::ENOENT
        end

        limits
      end

      def self.pam_freeze(uuid)
        limits = self.get_pam_limits(uuid)
        limits["nproc"]=0
        init_pam_limits(uuid, limits)
      end

      def self.remove_pam_limits_all
        config = OpenShift::Config.new
        gecos = (config.get("GEAR_GECOS") || "OO application container")

        uuids=[]
        Etc.passwd do |pwent|
          uuids << pwent.name if pwent.gecos == gecos
        end

        uuids.each do |uuid|
          remove_pam_limits(uuid)
        end
      end

      def self.remove_pam_limits(uuid)
        resource = OpenShift::Config.new('/etc/openshift/resource_limits.conf')
        limits_order = (resource.get('limits_order') or DEFAULT_PAM_LIMITS_ORDER)
        limits_file = PathUtils.join(DEFAULT_PAM_LIMITS_DIR, "#{limits_order}-#{uuid}.conf")
        begin
          File.unlink(limits_file)
        rescue Errno::ENOENT
        end
      end

    end
  end
end
