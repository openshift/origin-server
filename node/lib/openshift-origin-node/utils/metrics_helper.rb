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

module OpenShift
  module Runtime
    module Utils

      class MetricsHelper
        DEFAULT_METADATA = "appName:OPENSHIFT_APP_NAME,gear:OPENSHIFT_GEAR_UUID,app:OPENSHIFT_APP_UUID,ns:OPENSHIFT_NAMESPACE"

        # Constructs a Hash of mappings from user-defined key (e.g. appUuid)
        # to env var (e.g. OPENSHIFT_APP_UUID), for example:
        #
        # {'appName' => 'OPENSHIFT_APP_NAME', 'gear' => 'OPENSHIFT_GEAR_UUID'}
        #
        # Line must be of the form $key1:$env_var1,$key2:$env_var2,...
        #
        # e.g. appName:OPENSHIFT_APP_NAME,gear:OPENSHIFT_GEAR_UUID,app:OPENSHIFT_APP_UUID,ns:OPENSHIFT_NAMESPACE
        #
        # The following env vars are explicitly excluded:
        # - OPENSHIFT_SECRET_TOKEN
        def self.metrics_metadata(config)
          metadata_line = config.get('METRICS_METADATA') || DEFAULT_METADATA

          return {}.tap do |hash|
            pairs = metadata_line.split(',')

            pairs.each do |pair|
              key, env_var = pair.split(':')
              env_var.strip!

              next if 'OPENSHIFT_SECRET_TOKEN' == env_var

              hash[key.strip] = env_var
            end
          end
        end

      end

    end
  end
end
