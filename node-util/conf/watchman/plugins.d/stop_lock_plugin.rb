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

# Provide Watchman monitoring of gear stop_lock vs status
class StopLockPlugin < OpenShift::Runtime::WatchmanPlugin

  # execute plugin code
  def apply
    @gears.each do |uuid|
      return unless @gears.stop_lock?(uuid)
      return unless @gears.running?(uuid)

      # Gear has a stop_lock file and a state of running... remove stop_lock
      FileUtils.rm_f(@gears.stop_lock(uuid))

      state = @gears.state(uuid)
      Syslog.info("watchman deleted stop lock for gear #{uuid} because the state of the gear was #{state}")
    end
  end
end