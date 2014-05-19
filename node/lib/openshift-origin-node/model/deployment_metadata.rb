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

      [:git_ref, :git_sha1, :id, :hot_deploy, :force_clean_build, :activations, :checksum].each do |attr_name|
        define_method(attr_name) do
          @metadata[attr_name]
        end

        define_method("#{attr_name}=") do |value|
          @metadata[attr_name] = value
        end
      end

      def record_activation
        self.activations << Time.now.to_f
      end

      # Creates a new DeploymentMetadata instance for the given deployment_datetime.
      #
      # If the file doesn't exist, create it and set the defaults.
      #   If unable to create the file, log message and set the defaults.
      # If the file does exist, load it from disk.
      #
      # @param container           [ApplicationContainer] model of OpenShift application
      # @param deployment_datetime [#to_s]                Timestamp of deployment in question
      def initialize(container, deployment_datetime)
        @file = PathUtils.join(container.container_dir, 'app-deployments', deployment_datetime, 'metadata.json')

        empty = File.exists?(@file) && File.stat(@file).size == 0
        container.logger.warn("#{@file} was found empty. Will attempt to write defaults") if empty

        if File.exists?(@file) && !empty
          load
        else
          File.new(@file, 'w', 0644)
          @metadata = defaults
          container.set_rw_permission(@file)

          save

        end
      rescue => e
        container.logger.warn("Unable to create or update #{@file}. Gear may be exceeding quota. #{e.message}")
        @metadata = defaults
      end

      def load
        File.open(@file, 'r') do |f|
          # JSON.load is not used to prevent class injection. BZ#1086427
          @metadata = HashWithIndifferentAccess.new(JSON.parse(f.read))
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
          activations: @metadata[:activations],
          checksum: @metadata[:checksum]
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
          activations: [],
          checksum: nil
        }
      end
    end
  end
end
