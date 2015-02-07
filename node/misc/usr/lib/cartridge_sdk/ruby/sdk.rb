#
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
#

# bz1187829 - don't let gems in $GEM_HOME override OpenShift-provided ones
ENV['GEM_HOME'] = ''

require 'openshift-origin-node/model/application_container'
require 'openshift-origin-node/utils/environ'

module OpenShift
  module CartridgeSdk

    def primary_cartridge
      return @primary_cartridge unless @primary_cartridge.nil?
      OpenShift::Runtime::NodeLogger.disable
      container = OpenShift::Runtime::ApplicationContainer.from_uuid(ENV['OPENSHIFT_GEAR_UUID'])
      @primary_cartridge = container.cartridge_model.primary_cartridge
    end

    def primary_cartridge_manifest
      primary_cartridge.manifest
    end

    def app_web_to_proxy_ratio_and_colocated_gears
      container = OpenShift::Runtime::ApplicationContainer.from_uuid(ENV['OPENSHIFT_GEAR_UUID'])
      gr = container.gear_registry
      w = gr.entries[:web].keys.length
      p = gr.entries[:proxy].keys.length
      "#{(w/p.to_f).round} #{(gr.entries[:web].keys & gr.entries[:proxy].keys).join(" ")}"
    end

    def latest_deployment_metadata
      container = OpenShift::Runtime::ApplicationContainer.from_uuid(ENV['OPENSHIFT_GEAR_UUID'])
      container.deployment_metadata_for(container.latest_deployment_datetime)
    end

    def get_path_from_elements(element_name)
      env = ENV
      primary_name = File.basename(env['OPENSHIFT_PRIMARY_CARTRIDGE_DIR']).upcase
      env.delete(element_name)
      OpenShift::Runtime::Utils::Environ.collect_elements_from(env, element_name, primary_name).join(':')
    end

  end
end

