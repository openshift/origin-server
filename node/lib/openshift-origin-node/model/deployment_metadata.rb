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

require 'json'
require 'openshift-origin-node/utils/node_logger'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'

module OpenShift
  module Runtime
    class DeploymentMetadata
      [:git_ref, :git_sha1, :id, :hot_deploy, :force_clean_build, :activations].each do |attr_name|
        define_method(attr_name) do
          @metadata[attr_name]
        end

        define_method("#{attr_name}=") do |value|
          @metadata[attr_name] = value
          save
          @metadata[attr_name]
        end
      end

      # Creates a new DeploymentMetadata instance for the given deployment_datetime.
      #
      # If the file doesn't exist, create it and set the defaults.
      #
      # If the file does exist, load it from disk.
      def initialize(container, deployment_datetime)
        @file = PathUtils.join(container.container_dir, 'app-deployments', deployment_datetime, 'metadata.json')

        if File.exist?(@file)
          load
        else
          File.new(@file, "w", 0o0644)
          container.set_rw_permission(@file)

          @metadata = defaults

          save
        end
      end

      def load
        File.open(@file, "r") do |f|
          @metadata = HashWithIndifferentAccess.new(JSON.load(f))
        end
      end

      def save
        File.open(@file, "w") { |f| f.write JSON.dump(self) }
      end

      def as_json(options={})
        {
          git_ref: @metadata[:git_ref],
          git_sha1: @metadata[:git_sha1],
          id: @metadata[:id],
          hot_deploy: @metadata[:hot_deploy],
          force_clean_build: @metadata[:force_clean_build],
          activations: @metadata[:activations]
        }
      end

      private

      def defaults
        {
          git_ref: 'master',
          git_sha1: nil,
          id: nil,
          hot_deploy: nil,
          force_clean_build: nil,
          activations: []
        }
      end
    end
  end
end
