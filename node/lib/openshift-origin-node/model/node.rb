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
require 'openshift-origin-node/model/application_container'
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

      DEFAULT_NODE_PROFILE         = 'small'
      DEFAULT_QUOTA_BLOCKS         = '1048576'
      DEFAULT_QUOTA_FILES          = '80000'
      DEFAULT_NO_OVERCOMMIT_ACTIVE = false
      DEFAULT_MAX_ACTIVE_GEARS     = 0

      @@resource_limits_cache = nil

      def self.resource_limits
        unless @@resource_limits_cache
          limits = '/etc/openshift/resource_limits.conf'
          if File.readable? limits
            @@resource_limits_cache = OpenShift::Config.new(limits)
          else
            return nil
          end
        end
        return @@resource_limits_cache
      end

      def self.get_cartridge_list(list_descriptors = false, porcelain = false, oo_debug = false)
        carts = []
        CartridgeRepository.instance.latest_versions do |cartridge|
          begin
            print "Loading (#{cartridge.cartridge_vendor}, #{cartridge.name}, #{cartridge.version}, #{cartridge.cartridge_version})..." if oo_debug

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

      def self.get_quota(uuid, resolve=true)
        begin
          Etc.getpwnam(uuid) if resolve
        rescue ArgumentError
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Unable to obtain quota user #{uuid} does not exist",
                                                        :error))
        end

        resolve_opt      = resolve ? "--always-resolve" : ""
        stdout, _, _ = Utils.oo_spawn("quota -p #{resolve_opt} -w #{uuid}")
        results      = stdout.split("\n").grep(%r(^.*/dev/))
        if results.empty?
          raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Unable to obtain quota for user #{uuid}",
                                                        :error))
        end

        results = results.first.strip.split(' ')

        {device:      results[0],
         blocks_used: results[1].to_i, blocks_quota: results[2].to_i, blocks_limit: results[3].to_i,
         inodes_used: results[5].to_i, inodes_quota: results[6].to_i, inodes_limit: results[7].to_i
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

      def self.check_quotas(uuid, watermark)
        output = []
        quota  = self.get_quota(uuid)
        usage  = (quota[:blocks_used] / quota[:blocks_limit].to_f) * 100.0

        if watermark < usage
          output << "Warning: Gear #{uuid} is using %3.1f%% of disk quota" % usage
        end

        usage = (quota[:inodes_used] / quota[:inodes_limit].to_f) * 100.0
        if watermark < usage
          output << "Warning: Gear #{uuid} is using %3.1f%% of inodes allowed" % usage
        end
        return output
      rescue Exception => e
        return []
      end

      def self.set_quota(uuid, blocksmax, inodemax, resolve=true)
        current_quota, current_inodes, cur_quota = 0, 0, nil

        begin
          cur_quota = get_quota(uuid, resolve)
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
          # rather than raise Exception, allow current_quota to exceed limit and exceed buffer to allow gear moves, restarts, stops, idles to complete
          if current_quota > blocksmax.to_i * 1.5
             raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Current usage #{current_quota} exceeds requested quota #{blocksmax}",
                                                        :error))
          end
        end

        if current_inodes > inodemax.to_i
          # rather than raise Exception, allow current_inodes to exceed limit and exceed buffer to allow gear moves, restarts, stops, idles to complete
          if current_inodes > inodemax.to_i * 1.5
             raise NodeCommandException.new(
                    Utils::Sdk.translate_out_for_client("Current inodes #{current_inodes} exceeds requested inodes #{inodemax}",
                                                        :error))
          end
        end

        mountpoint      = self.get_gear_mountpoint
        resolve_opt      = resolve ? "--always-resolve" : ""
        cmd             = "setquota #{resolve_opt} -u #{uuid} 0 #{blocksmax} 0 #{inodemax} -a #{mountpoint}"
        _, stderr, rc = Utils.oo_spawn(cmd)
        raise NodeCommandException.new "Error: #{stderr} executing command #{cmd}" unless rc == 0
      end

      def self.init_quota(uuid, blocksmax=nil, inodemax=nil)
        resource = resource_limits
        blocksmax = (blocksmax or resource.get('quota_blocks') or DEFAULT_QUOTA['quota_blocks'])
        inodemax  = (inodemax  or resource.get('quota_files')  or DEFAULT_QUOTA['quota_files'])
        self.set_quota(uuid, blocksmax.to_i, inodemax.to_i)
      end

      def self.remove_quota(uuid, resolve=true)
        begin
          self.set_quota(uuid, 0, 0, resolve)
        rescue NodeCommandException
          # If the user no longer exists than it has no quota.
          # NB: there are other exceptions too, such as if the gear is still using space on the disk somehow.
        end
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
        resource = resource_limits
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
        resource = resource_limits
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
        resource = resource_limits
        limits_order = (resource.get('limits_order') or DEFAULT_PAM_LIMITS_ORDER)
        limits_file = PathUtils.join(DEFAULT_PAM_LIMITS_DIR, "#{limits_order}-#{uuid}.conf")
        begin
          File.unlink(limits_file)
        rescue Errno::ENOENT
        end
      end

      def self.node_utilization
        res = Hash.new(nil)

        resource = resource_limits
        return res unless resource

        res['node_profile'] = resource.get('node_profile', DEFAULT_NODE_PROFILE)
        res['quota_blocks'] = resource.get('quota_blocks', DEFAULT_QUOTA_BLOCKS)
        res['quota_files'] = resource.get('quota_files', DEFAULT_QUOTA_FILES)
        res['no_overcommit_active'] = resource.get_bool('no_overcommit_active', DEFAULT_NO_OVERCOMMIT_ACTIVE)

        # use max_{active_,}gears if set in resource limits, or fall back to old "apps" names
        res['max_active_gears'] = (resource.get('max_active_gears') or resource.get('max_active_apps') or DEFAULT_MAX_ACTIVE_GEARS)

        #
        # Count number of git repos and gear status counts
        #
        res['git_repos_count'] = 0
        res['gears_total_count'] = 0
        res['gears_idled_count'] = 0
        res['gears_stopped_count'] = 0
        res['gears_started_count'] = 0
        res['gears_deploying_count'] = 0
        res['gears_unknown_count'] = 0
        OpenShift::Runtime::ApplicationContainer.all(nil, false).each do |app|
          # res['git_repos_count'] += 1 if ApplicationRepository.new(app).exists?
          res['gears_total_count'] += 1

          case app.state.value
          # expected values: building, deploying, started, idle, new, stopped, or unknown
          when 'idle'
            res['gears_idled_count'] += 1
          when 'stopped'
            res['gears_stopped_count'] += 1
          when 'started'
            res['gears_started_count'] += 1
          when *%w[new building deploying]
            res['gears_deploying_count'] += 1
          else # literally 'unknown' or something else
            res['gears_unknown_count'] += 1
          end
        end

        # consider a gear active unless explicitly not
        res['gears_active_count'] = res['gears_total_count'] - res['gears_idled_count'] - res['gears_stopped_count']
        res['gears_usage_pct'] = begin res['gears_total_count'] * 100.0 / res['max_active_gears'].to_f; rescue; 0.0; end
        res['gears_active_usage_pct'] = begin res['gears_active_count'] * 100.0 / res['max_active_gears'].to_f; rescue; 0.0; end
        res['capacity'] = res['gears_usage_pct'].to_s
        res['active_capacity'] = res['gears_active_usage_pct'].to_s
        return res
      end
    end
  end
end
