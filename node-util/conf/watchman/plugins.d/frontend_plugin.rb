#--
# Copyright 2014 Red Hat, Inc.
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

require 'openshift-origin-node/model/watchman/watchman_plugin'

# Provide OpenShift with garbage collection for Frontend Proxy configurations
# @!attribute [r] next_check
#   @return [DateTime] timestamp for next check
class FrontendPlugin < OpenShift::Runtime::WatchmanPlugin
  attr_reader :next_check

  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] config
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] logger
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] gears
  # @param [see OpenShift::Runtime::WatchmanPlugin#initialize] operation
  # @param [lambda<>] next_update calculates the time for next check
  # @param [DateTime] epoch is when plugin was object instantiated
  def initialize(config, logger, gears, operation, next_update = nil, epoch = DateTime.now)
    super(config, logger, gears, operation)

    @deleted_age = 172800
    @deleted_age = ENV['FRONTEND_CLEANUP_PERIOD'].to_i unless ENV['FRONTEND_CLEANUP_PERIOD'].nil?

    @next_update = next_update || lambda { DateTime.now + Rational(@deleted_age, 86400) }
    @next_check  = epoch
  end

  # Test gears' environment for OPENSHIFT_GEAR_DNS existing
  # @param [OpenShift::Runtime::WatchmanPluginTemplate::Iteration] iteration not used
  # @return void
  def apply(iteration)
    return if DateTime.now < @next_check
    @next_check = @next_update.call

    reload_needed = false

    conf_dir = @config.get('OPENSHIFT_HTTP_CONF_DIR', '/etc/httpd/conf.d/openshift')
    Dir.glob(PathUtils.join(conf_dir, '*.conf')).each do |conf_file|
      next if File.size?(conf_file)
      next if File.mtime(conf_file) > (DateTime.now - Rational(1, 24))

      @logger.info %Q(watchman frontend plugin cleaned up #{conf_file})
      File.delete(conf_file)

      reload_needed = true

      # skip deleting the gear_dir if this is the _ha.conf file,
      # as deletion will be handled by the regular .conf file.
      next if conf_file.end_with?('_ha.conf')

      gear_dir = conf_file.gsub('_0_', '_')
      gear_dir = gear_dir.gsub('.conf', '')

      FileUtils.rm_r(gear_dir) if File.directory?(gear_dir)
    end

    # Cleanup the empty conf gear directories. For e.g. directories for scalable
    # application's db gears.
    Dir.glob(PathUtils.join(conf_dir, '*')).each do |entry|
      next unless File.directory?(entry)
      next unless Dir["#{entry}/*"].empty?

      # Verify name is of the form we expect for these directories i.e. gearuuid_domain_gearuuid
      dir_name = File.basename(entry)
      next if /(.*)_(.*)_(.*)/ !~ dir_name
      dir_name_parts = dir_name.split('_')
      next if dir_name_parts[0] != dir_name_parts[2]
      # Only remove the directory if the conf file which would have included it is gone.
      next unless Dir.glob(PathUtils.join(conf_dir, "#{dir_name_parts[0]}_#{dir_name_parts[1]}_*_#{dir_name_parts[2]}.conf")).length == 0

      FileUtils.rm_r(entry)
      @logger.info %Q(watchman frontend plugin cleaned up #{entry})
    end

    if reload_needed
      ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
    end
  end
end
